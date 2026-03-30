import Foundation
@testable import SignalBarCore
import XCTest

final class HealthEngineStallRecoveryTests: XCTestCase {
    func test_hungProbeRunnersTimeOutAndStillEmitUpdatedSnapshots() async throws {
        let pathMonitor = TestPathMonitor()
        let target = ProbeTarget(
            kind: .control,
            name: "Control",
            url: URL(string: "https://example.com/control")!,
            method: .head,
            interval: 15,
            timeout: 0.05)
        let engine = HealthEngine(
            pathMonitor: pathMonitor,
            dnsProbeRunner: HangingDNSProbeRunner(),
            httpProbeRunner: HangingHTTPProbeRunner(),
            controlTargets: [target],
            probeTimeoutGraceInterval: 0.05)

        let stream = await engine.start()
        let consumer = Task {
            var snapshots: [HealthSnapshot] = []
            for await snapshot in stream {
                snapshots.append(snapshot)
                if snapshots.count >= 4 {
                    break
                }
            }
            return snapshots
        }
        defer {
            pathMonitor.finish()
            consumer.cancel()
        }

        pathMonitor.yield(satisfiedPath())

        let snapshots = try await waitForSnapshots(from: consumer, timeout: 2)
        XCTAssertGreaterThanOrEqual(snapshots.count, 4)
        XCTAssertTrue(snapshots.contains(where: { $0.generatedAt > snapshots[1].generatedAt }))
        XCTAssertTrue(snapshots.contains(where: { $0.controlTargets.first?.latestDNS?.failure == .timeout }))
        XCTAssertTrue(snapshots.contains(where: { $0.controlTargets.first?.latestHTTP?.failure == .timeout }))
    }

    private func waitForSnapshots(
        from task: Task<[HealthSnapshot], Never>,
        timeout: TimeInterval)
        async throws -> [HealthSnapshot]
    {
        try await withThrowingTaskGroup(of: [HealthSnapshot].self) { group in
            group.addTask {
                await task.value
            }
            group.addTask {
                try await Task.sleep(for: .seconds(timeout))
                throw NSError(domain: "HealthEngineStallRecoveryTests", code: 1)
            }

            let snapshots = try await group.next()
            group.cancelAll()
            return snapshots ?? []
        }
    }

    private func satisfiedPath() -> PathSnapshot {
        PathSnapshot(
            observedAt: .now,
            status: .satisfied,
            interface: .wifi,
            isConstrained: false,
            isExpensive: false,
            supportsDNS: true,
            supportsIPv4: true,
            supportsIPv6: true)
    }
}

private final class TestPathMonitor: PathMonitoring, @unchecked Sendable {
    private let pathStream: AsyncStream<PathSnapshot>
    private let continuation: AsyncStream<PathSnapshot>.Continuation

    init() {
        var continuation: AsyncStream<PathSnapshot>.Continuation?
        pathStream = AsyncStream { continuation = $0 }
        self.continuation = continuation!
    }

    func stream() -> AsyncStream<PathSnapshot> {
        pathStream
    }

    func yield(_ path: PathSnapshot) {
        continuation.yield(path)
    }

    func finish() {
        continuation.finish()
    }
}

private struct HangingDNSProbeRunner: DNSProbing {
    func probe(target: ProbeTarget) async -> DNSProbeResult {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(60))
        }
        return DNSProbeResult(
            targetID: target.id,
            startedAt: .now,
            durationMs: nil,
            success: false,
            resolvedAddresses: 0,
            failure: .cancelled)
    }
}

private struct HangingHTTPProbeRunner: HTTPProbing {
    func probe(target: ProbeTarget) async -> HTTPProbeResult {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(60))
        }
        return HTTPProbeResult(
            targetID: target.id,
            startedAt: .now,
            dnsMs: nil,
            connectMs: nil,
            tlsMs: nil,
            firstByteMs: nil,
            totalMs: nil,
            statusCode: nil,
            success: false,
            reusedConnection: false,
            failure: .cancelled)
    }
}
