import Foundation

public actor HealthEngine {
    private let pathMonitor: any PathMonitoring
    private let dnsProbeRunner: any DNSProbing
    private let httpProbeRunner: any HTTPProbing
    private let controlTargets: [ProbeTarget]
    private let probeTimeoutGraceInterval: TimeInterval
    private let dnsHistoryLimit = 8
    private let httpHistoryLimit = 8

    private var watchedTarget: ProbeTarget?
    private var cadenceConfiguration: ProbeCadenceConfiguration
    private var continuation: AsyncStream<HealthSnapshot>.Continuation?
    private var currentPath: PathSnapshot?
    private var dnsHistory: [UUID: [DNSProbeResult]] = [:]
    private var httpHistory: [UUID: [HTTPProbeResult]] = [:]
    private var historyStore = ProbeHistoryStore()
    private var scheduler = ProbeScheduler()
    private var pathTask: Task<Void, Never>?
    private var dnsLoopTask: Task<Void, Never>?
    private var httpLoopTask: Task<Void, Never>?
    private var isPaused = false
    private var isDNSSweepInFlight = false
    private var isHTTPSweepInFlight = false

    public init(
        pathMonitor: any PathMonitoring = PathMonitorService(),
        dnsProbeRunner: any DNSProbing = DNSProbeRunner(),
        httpProbeRunner: any HTTPProbing = HTTPProbeRunner(),
        controlTargets: [ProbeTarget] = ProbeTarget.defaultControlTargets,
        watchedTarget: ProbeTarget? = nil,
        cadenceConfiguration: ProbeCadenceConfiguration = ProbeCadenceConfiguration(),
        probeTimeoutGraceInterval: TimeInterval = 0.5)
    {
        self.pathMonitor = pathMonitor
        self.dnsProbeRunner = dnsProbeRunner
        self.httpProbeRunner = httpProbeRunner
        self.controlTargets = controlTargets
        self.probeTimeoutGraceInterval = probeTimeoutGraceInterval
        self.watchedTarget = watchedTarget
        self.cadenceConfiguration = cadenceConfiguration
    }

    public func start() -> AsyncStream<HealthSnapshot> {
        AsyncStream { continuation in
            Task { await self.startInternal(continuation) }
        }
    }

    public func updateWatchedTarget(_ watchedTarget: ProbeTarget?) {
        self.watchedTarget = watchedTarget
        pruneHistoryToActiveTargets()
        restartSweepLoopsIfNeeded()
        emitSnapshot()
    }

    public func updateCadenceConfiguration(_ cadenceConfiguration: ProbeCadenceConfiguration) {
        self.cadenceConfiguration = cadenceConfiguration
        scheduler.updateCadenceConfiguration(cadenceConfiguration, among: activeTargetsForProbing(), now: .now)
        restartSweepLoopsIfNeeded()
    }

    public func refreshNow() async {
        await performDNSSweepIfNeeded(force: true)
        await performHTTPSweepIfNeeded(force: true)
        emitSnapshot()
    }

    public func pause() {
        isPaused = true
        restartSweepLoopsIfNeeded()
    }

    public func resume() {
        isPaused = false
        restartSweepLoopsIfNeeded()
    }

    public func historySnapshot(for window: HistoryWindow) -> HistorySnapshot {
        historyStore.historySnapshot(for: window)
    }

    private func startInternal(_ continuation: AsyncStream<HealthSnapshot>.Continuation) async {
        stopInternal()
        self.continuation = continuation
        let initialSnapshot = PathDNSHealthSnapshotBuilder.makeInitialSnapshot()
        historyStore.record(initialSnapshot)
        continuation.yield(initialSnapshot)

        let pathStream = pathMonitor.stream()
        pathTask = Task {
            for await path in pathStream {
                guard !Task.isCancelled else { break }
                await self.handlePathUpdate(path)
            }
        }

        startSweepLoops()

        continuation.onTermination = { _ in
            Task { await self.stopInternal() }
        }
    }

    private func activeTargetsForProbing() -> [ProbeTarget] {
        var targets = controlTargets.filter(\.enabled)
        if let watchedTarget, watchedTarget.enabled {
            targets.append(watchedTarget)
        }
        return targets
    }

    private func startSweepLoops() {
        dnsLoopTask?.cancel()
        httpLoopTask?.cancel()
        dnsLoopTask = makeSweepLoop(for: .dns)
        httpLoopTask = makeSweepLoop(for: .http)
    }

    private func restartSweepLoopsIfNeeded() {
        guard continuation != nil else { return }
        startSweepLoops()
    }

    private func makeSweepLoop(for kind: ProbeScheduler.SweepKind) -> Task<Void, Never> {
        Task {
            while !Task.isCancelled {
                guard let dueDate = await self.nextDueDate(for: kind) else {
                    try? await Task.sleep(for: .seconds(1))
                    continue
                }

                let sleepSeconds = max(0, dueDate.timeIntervalSinceNow)
                if sleepSeconds > 0 {
                    try? await Task.sleep(for: .seconds(sleepSeconds))
                }
                guard !Task.isCancelled else { break }

                switch kind {
                case .dns:
                    await self.performDNSSweepIfNeeded()
                case .http:
                    await self.performHTTPSweepIfNeeded()
                }
            }
        }
    }

    private func nextDueDate(for kind: ProbeScheduler.SweepKind) async -> Date? {
        guard !isPaused else { return nil }
        guard let currentPath, currentPath.status == .satisfied else { return nil }

        let isSweepInFlight = switch kind {
        case .dns:
            isDNSSweepInFlight
        case .http:
            isHTTPSweepInFlight
        }
        if isSweepInFlight {
            return .now.addingTimeInterval(max(0.25, probeTimeoutGraceInterval))
        }

        let activeTargets = activeTargetsForProbing()
        guard !activeTargets.isEmpty else { return nil }
        return scheduler.nextDueDate(for: kind, among: activeTargets, now: .now)
    }

    private func handlePathUpdate(_ path: PathSnapshot) async {
        currentPath = path
        if path.status != .satisfied {
            dnsHistory.removeAll()
            httpHistory.removeAll()
            scheduler.reset()
            emitSnapshot()
            restartSweepLoopsIfNeeded()
            return
        }

        emitSnapshot()
        guard !isPaused else {
            restartSweepLoopsIfNeeded()
            return
        }

        if dnsHistory.isEmpty {
            await performDNSSweepIfNeeded(force: true)
        }
        if httpHistory.isEmpty {
            await performHTTPSweepIfNeeded(force: true)
        }

        restartSweepLoopsIfNeeded()
    }

    private func performDNSSweepIfNeeded(force: Bool = false) async {
        guard !isDNSSweepInFlight else { return }
        guard let currentPath, currentPath.status == .satisfied else { return }
        guard !isPaused || force else { return }
        let activeTargets = activeTargetsForProbing()
        let dueTargets = force ? activeTargets : scheduler.dueTargets(for: .dns, among: activeTargets, now: .now)
        guard !dueTargets.isEmpty else { return }

        isDNSSweepInFlight = true
        defer { self.isDNSSweepInFlight = false }

        let probeResults = await withTaskGroup(of: DNSProbeResult.self, returning: [DNSProbeResult].self) { group in
            for target in dueTargets {
                let runner = self.dnsProbeRunner
                let timeoutInterval = self.fallbackTimeoutInterval(for: target)
                group.addTask {
                    await Self.probeDNSResult(
                        for: target,
                        runner: runner,
                        timeoutInterval: timeoutInterval)
                }
            }

            var results: [DNSProbeResult] = []
            for await result in group {
                results.append(result)
            }
            return results
        }

        guard let latestPath = self.currentPath, latestPath.status == .satisfied else { return }
        let completionDate = Date.now
        if force {
            scheduler.markFullSweepCompleted(dueTargets, for: .dns, completedAt: completionDate)
        } else {
            scheduler.markCompleted(dueTargets, for: .dns, completedAt: completionDate)
        }
        for result in probeResults {
            appendDNSResult(result)
        }
        emitSnapshot()
    }

    private func performHTTPSweepIfNeeded(force: Bool = false) async {
        guard !isHTTPSweepInFlight else { return }
        guard let currentPath, currentPath.status == .satisfied else { return }
        guard !isPaused || force else { return }
        let activeTargets = activeTargetsForProbing()
        let dueTargets = force ? activeTargets : scheduler.dueTargets(for: .http, among: activeTargets, now: .now)
        guard !dueTargets.isEmpty else { return }

        isHTTPSweepInFlight = true
        defer { self.isHTTPSweepInFlight = false }

        let probeResults = await withTaskGroup(of: HTTPProbeResult.self, returning: [HTTPProbeResult].self) { group in
            for target in dueTargets {
                let runner = self.httpProbeRunner
                let timeoutInterval = self.fallbackTimeoutInterval(for: target)
                group.addTask {
                    await Self.probeHTTPResult(
                        for: target,
                        runner: runner,
                        timeoutInterval: timeoutInterval)
                }
            }

            var results: [HTTPProbeResult] = []
            for await result in group {
                results.append(result)
            }
            return results
        }

        guard let latestPath = self.currentPath, latestPath.status == .satisfied else { return }
        let completionDate = Date.now
        if force {
            scheduler.markFullSweepCompleted(dueTargets, for: .http, completedAt: completionDate)
        } else {
            scheduler.markCompleted(dueTargets, for: .http, completedAt: completionDate)
        }
        for result in probeResults {
            appendHTTPResult(result)
        }
        emitSnapshot()
    }

    private static func probeDNSResult(
        for target: ProbeTarget,
        runner: any DNSProbing,
        timeoutInterval: TimeInterval)
        async -> DNSProbeResult
    {
        let startedAt = Date.now

        return await withTaskGroup(of: DNSProbeResult.self, returning: DNSProbeResult.self) { group in
            group.addTask {
                await runner.probe(target: target)
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(timeoutInterval))
                return DNSProbeResult(
                    targetID: target.id,
                    startedAt: startedAt,
                    durationMs: max(0, timeoutInterval * 1000),
                    success: false,
                    resolvedAddresses: 0,
                    failure: .timeout)
            }

            let result = await group.next() ?? DNSProbeResult(
                targetID: target.id,
                startedAt: startedAt,
                durationMs: max(0, timeoutInterval * 1000),
                success: false,
                resolvedAddresses: 0,
                failure: .unknown)
            group.cancelAll()
            return result
        }
    }

    private static func probeHTTPResult(
        for target: ProbeTarget,
        runner: any HTTPProbing,
        timeoutInterval: TimeInterval)
        async -> HTTPProbeResult
    {
        let startedAt = Date.now

        return await withTaskGroup(of: HTTPProbeResult.self, returning: HTTPProbeResult.self) { group in
            group.addTask {
                await runner.probe(target: target)
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(timeoutInterval))
                return HTTPProbeResult(
                    targetID: target.id,
                    startedAt: startedAt,
                    dnsMs: nil,
                    connectMs: nil,
                    tlsMs: nil,
                    firstByteMs: nil,
                    totalMs: max(0, timeoutInterval * 1000),
                    statusCode: nil,
                    success: false,
                    reusedConnection: false,
                    failure: .timeout)
            }

            let result = await group.next() ?? HTTPProbeResult(
                targetID: target.id,
                startedAt: startedAt,
                dnsMs: nil,
                connectMs: nil,
                tlsMs: nil,
                firstByteMs: nil,
                totalMs: max(0, timeoutInterval * 1000),
                statusCode: nil,
                success: false,
                reusedConnection: false,
                failure: .unknown)
            group.cancelAll()
            return result
        }
    }

    private func fallbackTimeoutInterval(for target: ProbeTarget) -> TimeInterval {
        max(target.timeout + probeTimeoutGraceInterval, target.timeout)
    }

    private func appendDNSResult(_ result: DNSProbeResult) {
        var history = dnsHistory[result.targetID] ?? []
        history.append(result)
        if history.count > dnsHistoryLimit {
            history.removeFirst(history.count - dnsHistoryLimit)
        }
        dnsHistory[result.targetID] = history
    }

    private func appendHTTPResult(_ result: HTTPProbeResult) {
        var history = httpHistory[result.targetID] ?? []
        history.append(result)
        if history.count > httpHistoryLimit {
            history.removeFirst(history.count - httpHistoryLimit)
        }
        httpHistory[result.targetID] = history
    }

    private func pruneHistoryToActiveTargets() {
        let activeTargetIDs = Set(activeTargetsForProbing().map(\.id))
        dnsHistory = dnsHistory.filter { activeTargetIDs.contains($0.key) }
        httpHistory = httpHistory.filter { activeTargetIDs.contains($0.key) }
    }

    private func emitSnapshot() {
        let snapshot = PathDNSHealthSnapshotBuilder.makeSnapshot(
            path: currentPath,
            controlTargets: controlTargets,
            watchedTarget: watchedTarget,
            dnsHistory: dnsHistory,
            httpHistory: httpHistory,
            at: .now)
        historyStore.record(snapshot)
        continuation?.yield(snapshot)
    }

    private func stopInternal() {
        pathTask?.cancel()
        dnsLoopTask?.cancel()
        httpLoopTask?.cancel()
        pathTask = nil
        dnsLoopTask = nil
        httpLoopTask = nil
        continuation = nil
        currentPath = nil
        dnsHistory.removeAll()
        httpHistory.removeAll()
        historyStore.reset()
        scheduler.reset()
        isDNSSweepInFlight = false
        isHTTPSweepInFlight = false
    }
}
