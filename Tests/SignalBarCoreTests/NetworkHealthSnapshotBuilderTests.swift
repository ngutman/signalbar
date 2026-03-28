@testable import SignalBarCore
import XCTest

final class NetworkHealthSnapshotBuilderTests: XCTestCase {
    private let path = PathSnapshot(
        observedAt: Date(timeIntervalSince1970: 100),
        status: .satisfied,
        interface: .wifi,
        isConstrained: false,
        isExpensive: false,
        supportsDNS: true,
        supportsIPv4: true,
        supportsIPv6: true)

    func test_healthyHTTPHistoryMarksInternetAndQualityHealthy() {
        let targets = ProbeTarget.defaultControlTargets
        let dnsHistory = Dictionary(uniqueKeysWithValues: targets.map { target in
            (
                target.id,
                [DNSProbeResult(
                    targetID: target.id,
                    startedAt: Date(timeIntervalSince1970: 101),
                    durationMs: 25,
                    success: true,
                    resolvedAddresses: 2,
                    failure: nil)])
        })
        let httpHistory = Dictionary(uniqueKeysWithValues: targets.enumerated().map { index, target in
            (target.id, [
                HTTPProbeResult(
                    targetID: target.id,
                    startedAt: Date(timeIntervalSince1970: 102 + Double(index * 2)),
                    dnsMs: 8,
                    connectMs: 12,
                    tlsMs: 18,
                    firstByteMs: 30,
                    totalMs: 52 + Double(index),
                    statusCode: target.expectedStatusCodes?.first,
                    success: true,
                    reusedConnection: false,
                    failure: nil),
                HTTPProbeResult(
                    targetID: target.id,
                    startedAt: Date(timeIntervalSince1970: 108 + Double(index * 2)),
                    dnsMs: 8,
                    connectMs: 12,
                    tlsMs: 18,
                    firstByteMs: 30,
                    totalMs: 56 + Double(index),
                    statusCode: target.expectedStatusCodes?.first,
                    success: true,
                    reusedConnection: false,
                    failure: nil)
            ])
        })

        let snapshot = PathDNSHealthSnapshotBuilder.makeSnapshot(
            path: path,
            controlTargets: targets,
            dnsHistory: dnsHistory,
            httpHistory: httpHistory,
            at: Date(timeIntervalSince1970: 110))

        XCTAssertEqual(snapshot.layers.map(\.status), [.healthy, .healthy, .healthy, .healthy])
        XCTAssertEqual(snapshot.diagnosis.title, "Healthy")
        XCTAssertEqual(snapshot.jitterMs, 4)
    }

    func test_failedHTTPHistoryMarksInternetFailedAndQualityUnavailable() {
        let targets = ProbeTarget.defaultControlTargets
        let dnsHistory = Dictionary(uniqueKeysWithValues: targets.map { target in
            (
                target.id,
                [DNSProbeResult(
                    targetID: target.id,
                    startedAt: Date(timeIntervalSince1970: 111),
                    durationMs: 22,
                    success: true,
                    resolvedAddresses: 2,
                    failure: nil)])
        })
        let httpHistory = Dictionary(uniqueKeysWithValues: targets.map { target in
            (
                target.id,
                [HTTPProbeResult(
                    targetID: target.id,
                    startedAt: Date(timeIntervalSince1970: 112),
                    dnsMs: 8,
                    connectMs: 12,
                    tlsMs: nil,
                    firstByteMs: nil,
                    totalMs: 2500,
                    statusCode: nil,
                    success: false,
                    reusedConnection: false,
                    failure: .timeout)])
        })

        let snapshot = PathDNSHealthSnapshotBuilder.makeSnapshot(
            path: path,
            controlTargets: targets,
            dnsHistory: dnsHistory,
            httpHistory: httpHistory,
            at: Date(timeIntervalSince1970: 113))

        XCTAssertEqual(snapshot.layers.map(\.status), [.healthy, .healthy, .failed, .unavailable])
        XCTAssertEqual(snapshot.diagnosis.title, "Internet issue")
    }

    func test_watchedTargetFailureBecomesServiceSpecificIssueWhenCoreInternetIsHealthy() {
        let targets = ProbeTarget.defaultControlTargets
        let watchedTarget = ProbeTarget(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            kind: .watched,
            name: "GitHub",
            url: URL(string: "https://github.com")!,
            method: .auto,
            interval: 15,
            timeout: 3.0)
        var dnsEntries = targets.map { target in
            (
                target.id,
                [DNSProbeResult(
                    targetID: target.id,
                    startedAt: Date(timeIntervalSince1970: 121),
                    durationMs: 20,
                    success: true,
                    resolvedAddresses: 2,
                    failure: nil)])
        }
        dnsEntries.append((
            watchedTarget.id,
            [DNSProbeResult(
                targetID: watchedTarget.id,
                startedAt: Date(timeIntervalSince1970: 121),
                durationMs: 21,
                success: true,
                resolvedAddresses: 2,
                failure: nil)]))
        let dnsHistory = Dictionary(uniqueKeysWithValues: dnsEntries)

        var httpEntries = targets.enumerated().map { index, target in
            (
                target.id,
                [HTTPProbeResult(
                    targetID: target.id,
                    startedAt: Date(timeIntervalSince1970: 122 + Double(index)),
                    dnsMs: 8,
                    connectMs: 12,
                    tlsMs: 16,
                    firstByteMs: 20,
                    totalMs: 55 + Double(index),
                    statusCode: target.expectedStatusCodes?.first,
                    success: true,
                    reusedConnection: false,
                    failure: nil)])
        }
        httpEntries.append((
            watchedTarget.id,
            [HTTPProbeResult(
                targetID: watchedTarget.id,
                startedAt: Date(timeIntervalSince1970: 130),
                dnsMs: 8,
                connectMs: 12,
                tlsMs: nil,
                firstByteMs: nil,
                totalMs: 2500,
                statusCode: nil,
                success: false,
                reusedConnection: false,
                failure: .timeout)]))
        let httpHistory = Dictionary(uniqueKeysWithValues: httpEntries)

        let snapshot = PathDNSHealthSnapshotBuilder.makeSnapshot(
            path: path,
            controlTargets: targets,
            watchedTarget: watchedTarget,
            dnsHistory: dnsHistory,
            httpHistory: httpHistory,
            at: Date(timeIntervalSince1970: 131))

        XCTAssertEqual(snapshot.diagnosis.layer, .watchedService)
        XCTAssertEqual(snapshot.diagnosis.title, "Service-specific issue")
        XCTAssertEqual(snapshot.watchedTarget?.target.name, "GitHub")
    }

    func test_highJitterMarksQualityDegraded() {
        let targets = ProbeTarget.defaultControlTargets
        let dnsHistory = Dictionary(uniqueKeysWithValues: targets.map { target in
            (
                target.id,
                [DNSProbeResult(
                    targetID: target.id,
                    startedAt: Date(timeIntervalSince1970: 114),
                    durationMs: 20,
                    success: true,
                    resolvedAddresses: 2,
                    failure: nil)])
        })
        let targetTotals: [[Double]] = [
            [60, 130],
            [70, 140],
            [65, 135]
        ]
        let httpHistory = Dictionary(uniqueKeysWithValues: zip(targets, targetTotals).enumerated().map { index, pair in
            let (target, totals) = pair
            return (target.id, [
                HTTPProbeResult(
                    targetID: target.id,
                    startedAt: Date(timeIntervalSince1970: 115 + Double(index * 2)),
                    dnsMs: 8,
                    connectMs: 12,
                    tlsMs: 16,
                    firstByteMs: 24,
                    totalMs: totals[0],
                    statusCode: target.expectedStatusCodes?.first,
                    success: true,
                    reusedConnection: false,
                    failure: nil),
                HTTPProbeResult(
                    targetID: target.id,
                    startedAt: Date(timeIntervalSince1970: 121 + Double(index * 2)),
                    dnsMs: 8,
                    connectMs: 12,
                    tlsMs: 16,
                    firstByteMs: 24,
                    totalMs: totals[1],
                    statusCode: target.expectedStatusCodes?.first,
                    success: true,
                    reusedConnection: false,
                    failure: nil)
            ])
        })

        let snapshot = PathDNSHealthSnapshotBuilder.makeSnapshot(
            path: path,
            controlTargets: targets,
            dnsHistory: dnsHistory,
            httpHistory: httpHistory,
            at: Date(timeIntervalSince1970: 130))

        XCTAssertEqual(snapshot.layers.map(\.status), [.healthy, .healthy, .healthy, .degraded])
        XCTAssertEqual(snapshot.diagnosis.title, "Flaky")
        XCTAssertEqual(snapshot.jitterMs, 70)
    }

    func test_snapshotJitterUsesMedianOfPerTargetJitter() {
        let targets = ProbeTarget.defaultControlTargets
        let dnsHistory = Dictionary(uniqueKeysWithValues: targets.map { target in
            (
                target.id,
                [DNSProbeResult(
                    targetID: target.id,
                    startedAt: Date(timeIntervalSince1970: 200),
                    durationMs: 20,
                    success: true,
                    resolvedAddresses: 2,
                    failure: nil)])
        })
        let targetTotals: [[Double]] = [
            [100, 150],
            [110, 160],
            [120, 140]
        ]
        let httpHistory = Dictionary(uniqueKeysWithValues: zip(targets, targetTotals).enumerated().map { index, pair in
            let (target, totals) = pair
            return (target.id, [
                HTTPProbeResult(
                    targetID: target.id,
                    startedAt: Date(timeIntervalSince1970: 201 + Double(index * 2)),
                    dnsMs: 8,
                    connectMs: 12,
                    tlsMs: 16,
                    firstByteMs: 24,
                    totalMs: totals[0],
                    statusCode: target.expectedStatusCodes?.first,
                    success: true,
                    reusedConnection: false,
                    failure: nil),
                HTTPProbeResult(
                    targetID: target.id,
                    startedAt: Date(timeIntervalSince1970: 207 + Double(index * 2)),
                    dnsMs: 8,
                    connectMs: 12,
                    tlsMs: 16,
                    firstByteMs: 24,
                    totalMs: totals[1],
                    statusCode: target.expectedStatusCodes?.first,
                    success: true,
                    reusedConnection: false,
                    failure: nil)
            ])
        })

        let snapshot = PathDNSHealthSnapshotBuilder.makeSnapshot(
            path: path,
            controlTargets: targets,
            dnsHistory: dnsHistory,
            httpHistory: httpHistory,
            at: Date(timeIntervalSince1970: 220))

        XCTAssertEqual(snapshot.controlTargets.compactMap(\.jitterMs), [50, 50, 20])
        XCTAssertEqual(snapshot.jitterMs, 50)
    }
}
