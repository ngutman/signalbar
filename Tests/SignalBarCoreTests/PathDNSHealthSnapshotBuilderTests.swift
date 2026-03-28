@testable import SignalBarCore
import XCTest

final class PathDNSHealthSnapshotBuilderTests: XCTestCase {
    private let path = PathSnapshot(
        observedAt: Date(timeIntervalSince1970: 10),
        status: .satisfied,
        interface: .wifi,
        isConstrained: false,
        isExpensive: false,
        supportsDNS: true,
        supportsIPv4: true,
        supportsIPv6: true)

    func test_connectedPathWithoutDNSHistoryKeepsDNSPending() {
        let snapshot = PathDNSHealthSnapshotBuilder.makeSnapshot(
            path: path,
            controlTargets: ProbeTarget.defaultControlTargets,
            dnsHistory: [:],
            at: Date(timeIntervalSince1970: 11))

        XCTAssertEqual(snapshot.layers.map(\.status), [.healthy, .pending, .pending, .pending])
        XCTAssertEqual(snapshot.diagnosis.title, "Path connected")
    }

    func test_healthyDNSHistoryMarksDNSHealthy() {
        let targets = ProbeTarget.defaultControlTargets
        let history = Dictionary(uniqueKeysWithValues: targets.map { target in
            (target.id, [
                DNSProbeResult(
                    targetID: target.id,
                    startedAt: Date(timeIntervalSince1970: 12),
                    durationMs: 28,
                    success: true,
                    resolvedAddresses: 2,
                    failure: nil)
            ])
        })

        let snapshot = PathDNSHealthSnapshotBuilder.makeSnapshot(
            path: path,
            controlTargets: targets,
            dnsHistory: history,
            at: Date(timeIntervalSince1970: 13))

        XCTAssertEqual(snapshot.layers.map(\.status), [.healthy, .healthy, .pending, .pending])
        XCTAssertEqual(snapshot.diagnosis.title, "DNS healthy")
        XCTAssertEqual(snapshot.medianLatencyMs, 28)
    }

    func test_failedDNSHistoryMarksDownstreamUnavailable() {
        let targets = ProbeTarget.defaultControlTargets
        let history = Dictionary(uniqueKeysWithValues: targets.map { target in
            (target.id, [
                DNSProbeResult(
                    targetID: target.id,
                    startedAt: Date(timeIntervalSince1970: 14),
                    durationMs: 2500,
                    success: false,
                    resolvedAddresses: 0,
                    failure: .timeout)
            ])
        })

        let snapshot = PathDNSHealthSnapshotBuilder.makeSnapshot(
            path: path,
            controlTargets: targets,
            dnsHistory: history,
            at: Date(timeIntervalSince1970: 15))

        XCTAssertEqual(snapshot.layers.map(\.status), [.healthy, .failed, .unavailable, .unavailable])
        XCTAssertEqual(snapshot.diagnosis.title, "DNS issue")
        XCTAssertEqual(snapshot.reliability, 0)
    }
}
