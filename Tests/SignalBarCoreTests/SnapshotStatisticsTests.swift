@testable import SignalBarCore
import XCTest

final class SnapshotStatisticsTests: XCTestCase {
    func test_medianSupportsOddAndEvenCounts() {
        XCTAssertEqual(SnapshotStatistics.median(of: []), nil)
        XCTAssertEqual(SnapshotStatistics.median(of: [3]), 3)
        XCTAssertEqual(SnapshotStatistics.median(of: [1, 3, 5]), 3)
        XCTAssertEqual(SnapshotStatistics.median(of: [1, 3, 5, 7]), 4)
    }

    func test_httpSuccessRateAndJitterUseHTTPSamples() {
        let targetID = UUID(uuidString: "77777777-7777-7777-7777-777777777777")!
        let samples = [
            HTTPProbeResult(
                targetID: targetID,
                startedAt: Date(timeIntervalSince1970: 1),
                dnsMs: nil,
                connectMs: nil,
                tlsMs: nil,
                firstByteMs: nil,
                totalMs: 50,
                statusCode: 200,
                success: true,
                reusedConnection: false,
                failure: nil),
            HTTPProbeResult(
                targetID: targetID,
                startedAt: Date(timeIntervalSince1970: 2),
                dnsMs: nil,
                connectMs: nil,
                tlsMs: nil,
                firstByteMs: nil,
                totalMs: 80,
                statusCode: 200,
                success: true,
                reusedConnection: false,
                failure: nil),
            HTTPProbeResult(
                targetID: targetID,
                startedAt: Date(timeIntervalSince1970: 3),
                dnsMs: nil,
                connectMs: nil,
                tlsMs: nil,
                firstByteMs: nil,
                totalMs: nil,
                statusCode: nil,
                success: false,
                reusedConnection: false,
                failure: .timeout)
        ]

        XCTAssertEqual(SnapshotStatistics.successRate(for: samples), 2.0 / 3.0, accuracy: 0.0001)
        XCTAssertEqual(SnapshotStatistics.jitter(of: Array(samples.prefix(2))), 30)
    }

    func test_overallScoreAveragesLayerScores() {
        let layers = [
            LayerHealthSnapshot(
                layer: .link,
                status: .healthy,
                score: 1,
                title: "",
                explanation: "",
                primaryMetricText: nil),
            LayerHealthSnapshot(
                layer: .dns,
                status: .healthy,
                score: 1,
                title: "",
                explanation: "",
                primaryMetricText: nil),
            LayerHealthSnapshot(
                layer: .internet,
                status: .degraded,
                score: 0.6,
                title: "",
                explanation: "",
                primaryMetricText: nil),
            LayerHealthSnapshot(
                layer: .quality,
                status: .failed,
                score: 0,
                title: "",
                explanation: "",
                primaryMetricText: nil)
        ]

        XCTAssertEqual(SnapshotStatistics.overallScore(for: layers), 0.65, accuracy: 0.0001)
    }
}
