import Foundation
@testable import SignalBarCore
import XCTest

final class HealthEnginePauseTests: XCTestCase {
    func test_pauseSkipsAutomaticSweepsUntilManualRefresh() async throws {
        let pathMonitor = TestPathMonitor()
        let counter = ProbeCounter()
        let target = target(name: "Control")
        let engine = HealthEngine(
            pathMonitor: pathMonitor,
            dnsProbeRunner: TestDNSProbeRunner(counter: counter),
            httpProbeRunner: TestHTTPProbeRunner(counter: counter),
            controlTargets: [target])

        await engine.pause()
        let stream = await engine.start()
        let consumer = Task {
            for await _ in stream where !Task.isCancelled {}
        }
        defer {
            pathMonitor.finish()
            consumer.cancel()
        }

        pathMonitor.yield(satisfiedPath())
        try await Task.sleep(for: .milliseconds(150))

        let pausedCounts = await counter.snapshot()
        XCTAssertEqual(pausedCounts.dns, 0)
        XCTAssertEqual(pausedCounts.http, 0)

        await engine.refreshNow()
        try await Task.sleep(for: .milliseconds(150))

        let refreshedCounts = await counter.snapshot()
        XCTAssertEqual(refreshedCounts.dns, 1)
        XCTAssertEqual(refreshedCounts.http, 1)
    }

    private func target(name: String) -> ProbeTarget {
        ProbeTarget(
            kind: .control,
            name: name,
            url: URL(string: "https://example.com/\(name.lowercased())")!,
            method: .head,
            interval: 15,
            timeout: 2.5)
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

private actor ProbeCounter {
    private var dns = 0
    private var http = 0

    func recordDNS() {
        dns += 1
    }

    func recordHTTP() {
        http += 1
    }

    func snapshot() -> (dns: Int, http: Int) {
        (dns, http)
    }
}

private struct TestDNSProbeRunner: DNSProbing {
    let counter: ProbeCounter

    func probe(target: ProbeTarget) async -> DNSProbeResult {
        await counter.recordDNS()
        return DNSProbeResult(
            targetID: target.id,
            startedAt: .now,
            durationMs: 12,
            success: true,
            resolvedAddresses: 1,
            failure: nil)
    }
}

private struct TestHTTPProbeRunner: HTTPProbing {
    let counter: ProbeCounter

    func probe(target: ProbeTarget) async -> HTTPProbeResult {
        await counter.recordHTTP()
        return HTTPProbeResult(
            targetID: target.id,
            startedAt: .now,
            dnsMs: 4,
            connectMs: 6,
            tlsMs: 8,
            firstByteMs: 10,
            totalMs: 18,
            statusCode: 204,
            success: true,
            reusedConnection: false,
            failure: nil)
    }
}
