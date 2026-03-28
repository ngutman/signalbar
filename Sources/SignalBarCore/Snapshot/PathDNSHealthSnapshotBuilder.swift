import Foundation

public enum PathDNSHealthSnapshotBuilder {
    public static func makeInitialSnapshot(at date: Date = .now) -> HealthSnapshot {
        PathOnlyHealthSnapshotBuilder.makeInitialSnapshot(at: date)
    }

    public static func makeSnapshot(
        path: PathSnapshot?,
        controlTargets: [ProbeTarget],
        watchedTarget: ProbeTarget? = nil,
        dnsHistory: [UUID: [DNSProbeResult]],
        httpHistory: [UUID: [HTTPProbeResult]] = [:],
        at date: Date = .now) -> HealthSnapshot
    {
        guard let path else {
            return makeInitialSnapshot(at: date)
        }

        switch path.status {
        case .satisfied:
            return connectedSnapshot(
                path: path,
                controlTargets: controlTargets,
                watchedTarget: watchedTarget,
                dnsHistory: dnsHistory,
                httpHistory: httpHistory,
                at: date)
        case .unsatisfied, .requiresConnection:
            return PathOnlyHealthSnapshotBuilder.makeSnapshot(path: path, at: date)
        }
    }

    private static func connectedSnapshot(
        path: PathSnapshot,
        controlTargets: [ProbeTarget],
        watchedTarget: ProbeTarget?,
        dnsHistory: [UUID: [DNSProbeResult]],
        httpHistory: [UUID: [HTTPProbeResult]],
        at date: Date) -> HealthSnapshot
    {
        let enabledControlTargets = controlTargets.filter(\.enabled)
        let controlTargetHealths = enabledControlTargets.map { target in
            TargetHealthFactory.makeTargetHealth(
                target: target,
                dnsHistory: dnsHistory[target.id] ?? [],
                httpHistory: httpHistory[target.id] ?? [])
        }
        let watchedTargetHealth = watchedTarget.map { target in
            TargetHealthFactory.makeTargetHealth(
                target: target,
                dnsHistory: dnsHistory[target.id] ?? [],
                httpHistory: httpHistory[target.id] ?? [])
        }

        let linkLayer = LayerHealthSnapshot(
            layer: .link,
            status: .healthy,
            score: 1,
            title: "Link healthy",
            explanation: "Active network path is satisfied.",
            primaryMetricText: path.interface?.displayName ?? "Connected")

        guard path.supportsDNS else {
            let layers = [
                linkLayer,
                LayerHealthSnapshot(
                    layer: .dns,
                    status: .failed,
                    score: 0,
                    title: "DNS unsupported",
                    explanation: "The current path does not report DNS support.",
                    primaryMetricText: "Unsupported"),
                LayerSnapshotFactory.unavailableLayer(
                    .internet,
                    explanation: "Internet reachability depends on DNS support."),
                LayerSnapshotFactory.unavailableLayer(
                    .quality,
                    explanation: "Quality depends on deeper reachability checks.")
            ]
            return HealthSnapshot(
                generatedAt: date,
                path: path,
                layers: layers,
                controlTargets: controlTargetHealths,
                watchedTarget: watchedTargetHealth,
                diagnosis: Diagnosis(
                    layer: .dns,
                    scope: .local,
                    severity: .failed,
                    title: "DNS unsupported",
                    summary: "The current network path does not report DNS support."),
                isStale: false,
                overallScore: SnapshotStatistics.overallScore(for: layers),
                medianLatencyMs: nil,
                jitterMs: nil,
                reliability: 0)
        }

        let allDNSSamples = enabledControlTargets.flatMap { dnsHistory[$0.id] ?? [] }
        guard !allDNSSamples.isEmpty else {
            let layers = [
                linkLayer,
                LayerSnapshotFactory.pendingLayer(
                    .dns,
                    explanation: "Waiting for DNS probe results.",
                    metric: "Pending"),
                LayerSnapshotFactory.pendingLayer(
                    .internet,
                    explanation: "Waiting for internet probes.",
                    metric: "Pending"),
                LayerSnapshotFactory.pendingLayer(
                    .quality,
                    explanation: "Waiting for quality probes.",
                    metric: "Pending")
            ]
            return HealthSnapshot(
                generatedAt: date,
                path: path,
                layers: layers,
                controlTargets: controlTargetHealths,
                watchedTarget: watchedTargetHealth,
                diagnosis: Diagnosis(
                    layer: .link,
                    scope: .none,
                    severity: .healthy,
                    title: "Path connected",
                    summary: "Local network path is connected. DNS, internet, and quality checks are pending."),
                isStale: false,
                overallScore: SnapshotStatistics.overallScore(for: layers),
                medianLatencyMs: nil,
                jitterMs: nil,
                reliability: 0)
        }

        let dnsSuccessRate = SnapshotStatistics.successRate(for: allDNSSamples)
        let dnsMedianLatencyMs = SnapshotStatistics.median(of: allDNSSamples.filter(\.success).compactMap(\.durationMs))
        let dnsStatus = LayerStatusEvaluator.dnsLayerStatus(
            successRate: dnsSuccessRate,
            medianLatencyMs: dnsMedianLatencyMs)
        let dnsLayer = LayerSnapshotFactory.dnsLayer(
            status: dnsStatus,
            successRate: dnsSuccessRate,
            medianLatencyMs: dnsMedianLatencyMs)

        if dnsStatus == .failed {
            let layers = [
                linkLayer,
                dnsLayer,
                LayerSnapshotFactory.unavailableLayer(
                    .internet,
                    explanation: "Internet reachability depends on working DNS."),
                LayerSnapshotFactory.unavailableLayer(
                    .quality,
                    explanation: "Quality depends on deeper reachability checks.")
            ]
            return HealthSnapshot(
                generatedAt: date,
                path: path,
                layers: layers,
                controlTargets: controlTargetHealths,
                watchedTarget: watchedTargetHealth,
                diagnosis: Diagnosis(
                    layer: .dns,
                    scope: .local,
                    severity: .failed,
                    title: "DNS issue",
                    summary: "Connected, but DNS lookups are failing."),
                isStale: false,
                overallScore: SnapshotStatistics.overallScore(for: layers),
                medianLatencyMs: dnsMedianLatencyMs,
                jitterMs: nil,
                reliability: dnsSuccessRate)
        }

        let allHTTPSamples = enabledControlTargets.flatMap { httpHistory[$0.id] ?? [] }
        guard !allHTTPSamples.isEmpty else {
            let layers = [
                linkLayer,
                dnsLayer,
                LayerSnapshotFactory.pendingLayer(
                    .internet,
                    explanation: "Waiting for internet probes.",
                    metric: "Pending"),
                LayerSnapshotFactory.pendingLayer(
                    .quality,
                    explanation: "Waiting for quality probes.",
                    metric: "Pending")
            ]
            let diagnosis = DiagnosisResolver.withWatchedTarget(
                base: DiagnosisResolver.diagnosis(
                    dnsStatus: dnsStatus,
                    internetStatus: .pending,
                    qualityStatus: .pending,
                    internetSuccessRate: nil),
                watchedTargetHealth: watchedTargetHealth,
                internetStatus: .pending,
                qualityStatus: .pending)
            return HealthSnapshot(
                generatedAt: date,
                path: path,
                layers: layers,
                controlTargets: controlTargetHealths,
                watchedTarget: watchedTargetHealth,
                diagnosis: diagnosis,
                isStale: false,
                overallScore: SnapshotStatistics.overallScore(for: layers),
                medianLatencyMs: dnsMedianLatencyMs,
                jitterMs: nil,
                reliability: dnsSuccessRate)
        }

        let httpSuccesses = allHTTPSamples.filter(\.success)
        let internetSuccessRate = SnapshotStatistics.successRate(for: allHTTPSamples)
        let internetMedianLatencyMs = SnapshotStatistics.median(of: httpSuccesses.compactMap(\.totalMs))
        let internetStatus = LayerStatusEvaluator.internetLayerStatus(
            successRate: internetSuccessRate,
            medianLatencyMs: internetMedianLatencyMs)
        let internetLayer = LayerSnapshotFactory.internetLayer(
            status: internetStatus,
            successRate: internetSuccessRate,
            medianLatencyMs: internetMedianLatencyMs)

        let qualityLayer: LayerHealthSnapshot
        let qualityStatus: LayerStatus
        let qualityJitterMs: Double?
        if internetStatus == .failed {
            qualityStatus = .unavailable
            qualityJitterMs = nil
            qualityLayer = LayerSnapshotFactory.unavailableLayer(
                .quality,
                explanation: "Quality depends on a reachable internet path.")
        } else {
            qualityJitterMs = TargetHealthFactory.aggregateJitter(for: controlTargetHealths)
            qualityStatus = LayerStatusEvaluator.qualityLayerStatus(
                successRate: internetSuccessRate,
                medianLatencyMs: internetMedianLatencyMs,
                jitterMs: qualityJitterMs,
                hasHTTPSamples: !allHTTPSamples.isEmpty)
            qualityLayer = LayerSnapshotFactory.qualityLayer(
                status: qualityStatus,
                successRate: internetSuccessRate,
                medianLatencyMs: internetMedianLatencyMs,
                jitterMs: qualityJitterMs)
        }

        let layers = [linkLayer, dnsLayer, internetLayer, qualityLayer]
        let baseDiagnosis = DiagnosisResolver.diagnosis(
            dnsStatus: dnsStatus,
            internetStatus: internetStatus,
            qualityStatus: qualityStatus,
            internetSuccessRate: internetSuccessRate)
        let diagnosis = DiagnosisResolver.withWatchedTarget(
            base: baseDiagnosis,
            watchedTargetHealth: watchedTargetHealth,
            internetStatus: internetStatus,
            qualityStatus: qualityStatus)
        let medianLatencyMs = internetMedianLatencyMs ?? dnsMedianLatencyMs
        let reliability = !allHTTPSamples.isEmpty ? internetSuccessRate : dnsSuccessRate
        return HealthSnapshot(
            generatedAt: date,
            path: path,
            layers: layers,
            controlTargets: controlTargetHealths,
            watchedTarget: watchedTargetHealth,
            diagnosis: diagnosis,
            isStale: false,
            overallScore: SnapshotStatistics.overallScore(for: layers),
            medianLatencyMs: medianLatencyMs,
            jitterMs: qualityJitterMs,
            reliability: reliability)
    }
}
