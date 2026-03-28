@testable import SignalBarCore
import XCTest

final class ProbeHistoryStoreTests: XCTestCase {
    func test_emptyStoreReturnsPendingPlaceholderHistory() {
        let store = ProbeHistoryStore()

        let history = store.historySnapshot(for: .fiveMinutes, at: Date(timeIntervalSince1970: 600))

        XCTAssertEqual(history.window, .fiveMinutes)
        XCTAssertEqual(history.layerTimelines.count, 4)
        XCTAssertEqual(history.layerTimelines.first?.segments, [
            LayerTimelineSegment(
                startDate: Date(timeIntervalSince1970: 300),
                endDate: Date(timeIntervalSince1970: 600),
                status: .pending)
        ])
    }

    func test_historyWindowExtendsLatestStateFromBeforeWindowStart() throws {
        var store = ProbeHistoryStore()
        store.record(makeSnapshot(at: 250, dnsStatus: .healthy))
        store.record(makeSnapshot(at: 450, dnsStatus: .failed))

        let history = store.historySnapshot(for: .fiveMinutes, at: Date(timeIntervalSince1970: 600))
        let dnsTimeline = try XCTUnwrap(history.layerTimelines.first(where: { $0.layer == .dns }))

        XCTAssertEqual(dnsTimeline.segments, [
            LayerTimelineSegment(
                startDate: Date(timeIntervalSince1970: 300),
                endDate: Date(timeIntervalSince1970: 450),
                status: .healthy),
            LayerTimelineSegment(
                startDate: Date(timeIntervalSince1970: 450),
                endDate: Date(timeIntervalSince1970: 600),
                status: .failed)
        ])
    }

    func test_metricTimelinesIncludePingJitterAndReliabilityValues() throws {
        var store = ProbeHistoryStore()
        store.record(makeSnapshot(at: 540, dnsStatus: .healthy, pingMs: 48, jitterMs: 8, reliability: 1.0))
        store.record(makeSnapshot(
            at: 570,
            dnsStatus: .healthy,
            pingMs: 132,
            jitterMs: 34,
            reliability: 0.92,
            httpFailure: true))
        store.record(makeSnapshot(at: 600, dnsStatus: .healthy, pingMs: 280, jitterMs: 74, reliability: 0.65))

        let history = store.historySnapshot(for: .oneMinute, at: Date(timeIntervalSince1970: 600))
        let reliabilityTimeline = try XCTUnwrap(history.reliabilityTimeline)

        XCTAssertEqual(history.pingTimeline?.latestValue, 280)
        XCTAssertEqual(history.pingTimeline?.points.last?.qualityBand, .bad)
        XCTAssertEqual(history.jitterTimeline?.latestValue, 74)
        XCTAssertEqual(history.jitterTimeline?.points.last?.qualityBand, .bad)
        XCTAssertEqual(reliabilityTimeline.latestValue, 65)
        XCTAssertEqual(reliabilityTimeline.points.last?.qualityBand, .bad)
        XCTAssertTrue(reliabilityTimeline.points.contains(where: \.hadFailure))
    }

    func test_storePrunesSamplesOlderThanRetentionWindow() throws {
        var store = ProbeHistoryStore(retentionDuration: 300)
        store.record(makeSnapshot(at: 0, dnsStatus: .healthy))
        store.record(makeSnapshot(at: 400, dnsStatus: .failed))

        let history = store.historySnapshot(for: .sixtyMinutes, at: Date(timeIntervalSince1970: 401))
        let dnsTimeline = try XCTUnwrap(history.layerTimelines.first(where: { $0.layer == .dns }))

        XCTAssertEqual(dnsTimeline.segments.last?.status, .failed)
        XCTAssertEqual(dnsTimeline.segments.last?.endDate, Date(timeIntervalSince1970: 401))
        XCTAssertEqual(dnsTimeline.segments.dropLast().last?.status, .pending)
    }

    func test_metricTimelineBucketsDoNotDuplicateCarriedBoundaryValues() throws {
        var store = ProbeHistoryStore()
        store.record(makeSnapshot(at: 539, dnsStatus: .healthy, pingMs: 73, jitterMs: 10, reliability: 1.0))
        store.record(makeSnapshot(at: 571, dnsStatus: .healthy, pingMs: 73, jitterMs: 12, reliability: 1.0))
        store.record(makeSnapshot(at: 596, dnsStatus: .healthy, pingMs: 50, jitterMs: 8, reliability: 1.0))

        let history = store.historySnapshot(for: .oneMinute, at: Date(timeIntervalSince1970: 600))
        let pingTimeline = try XCTUnwrap(history.pingTimeline)
        let nonNilValues = pingTimeline.points.compactMap(\.value)

        XCTAssertEqual(nonNilValues.count(where: { $0 == 73 }), 1)
        XCTAssertEqual(nonNilValues.last, 50)
    }

    func test_fiveMinuteOverviewRetainsRecentHealthyHistory() throws {
        var store = ProbeHistoryStore()
        for item in [540.0, 555.0, 570.0, 585.0, 600.0] {
            store.record(makeSnapshot(at: item, dnsStatus: .healthy, pingMs: 50, jitterMs: 10, reliability: 1.0))
        }

        let history = store.historySnapshot(for: .fiveMinutes, at: Date(timeIntervalSince1970: 600))

        XCTAssertTrue(history.layerTimelines.allSatisfy { $0.segments.last?.status == .healthy })
        XCTAssertTrue(history.layerTimelines.allSatisfy {
            guard let lastSegment = $0.segments.last else { return false }
            return lastSegment.startDate <= Date(timeIntervalSince1970: 555)
        })
    }

    private func makeSnapshot(
        at seconds: TimeInterval,
        dnsStatus: LayerStatus,
        pingMs: Double? = nil,
        jitterMs: Double? = nil,
        reliability: Double = 1,
        httpFailure: Bool = false) -> HealthSnapshot
    {
        let date = Date(timeIntervalSince1970: seconds)
        let targetID = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
        let target = ProbeTarget(
            id: targetID,
            kind: .control,
            name: "Apple",
            url: URL(string: "https://www.apple.com/library/test/success.html")!,
            method: .head,
            interval: 15,
            timeout: 2.5,
            expectedStatusCodes: [200])
        let latestHTTP: HTTPProbeResult? = {
            guard pingMs != nil || httpFailure else { return nil }
            return HTTPProbeResult(
                targetID: targetID,
                startedAt: date,
                dnsMs: 8,
                connectMs: 12,
                tlsMs: 16,
                firstByteMs: pingMs == nil ? nil : 20,
                totalMs: pingMs,
                statusCode: httpFailure ? nil : 200,
                success: !httpFailure,
                reusedConnection: false,
                failure: httpFailure ? .timeout : nil)
        }()

        return HealthSnapshot(
            generatedAt: date,
            path: nil,
            layers: [
                LayerHealthSnapshot(
                    layer: .link,
                    status: .healthy,
                    score: 1,
                    title: "Link",
                    explanation: "",
                    primaryMetricText: nil),
                LayerHealthSnapshot(
                    layer: .dns,
                    status: dnsStatus,
                    score: dnsStatus == .healthy ? 1 : 0,
                    title: "DNS",
                    explanation: "",
                    primaryMetricText: nil),
                LayerHealthSnapshot(
                    layer: .internet,
                    status: httpFailure ? .degraded : .healthy,
                    score: httpFailure ? 0.6 : 1,
                    title: "Internet",
                    explanation: "",
                    primaryMetricText: nil),
                LayerHealthSnapshot(
                    layer: .quality,
                    status: (jitterMs ?? 0) >= 30 ? .degraded : .healthy,
                    score: (jitterMs ?? 0) >= 30 ? 0.6 : 1,
                    title: "Quality",
                    explanation: "",
                    primaryMetricText: nil)
            ],
            controlTargets: [
                TargetHealth(
                    id: targetID,
                    target: target,
                    medianLatencyMs: pingMs,
                    jitterMs: jitterMs,
                    successRate: reliability,
                    lastFailureText: httpFailure ? "Timeout" : nil,
                    latestHTTP: latestHTTP,
                    latestDNS: nil)
            ],
            watchedTarget: nil,
            diagnosis: Diagnosis(layer: .unknown, scope: .none, severity: .healthy, title: "", summary: ""),
            isStale: false,
            overallScore: 1,
            medianLatencyMs: pingMs,
            jitterMs: jitterMs,
            reliability: reliability)
    }
}
