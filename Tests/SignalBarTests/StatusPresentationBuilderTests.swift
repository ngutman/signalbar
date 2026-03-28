@testable import SignalBar
import SignalBarCore
import XCTest

final class StatusPresentationBuilderTests: XCTestCase {
    func test_healthyTargetRowsHideRedundantSuccessAndJitterDetails() {
        let target = ProbeTarget(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            kind: .control,
            name: "Apple",
            url: URL(string: "https://www.apple.com/library/test/success.html")!,
            method: .head,
            interval: 15,
            timeout: 2.5,
            expectedStatusCodes: [200])
        let snapshot = HealthSnapshot(
            generatedAt: Date(timeIntervalSince1970: 100),
            path: nil,
            layers: healthyLayers,
            controlTargets: [
                TargetHealth(
                    id: target.id,
                    target: target,
                    medianLatencyMs: 56,
                    jitterMs: 12,
                    successRate: 1.0,
                    lastFailureText: nil,
                    latestHTTP: HTTPProbeResult(
                        targetID: target.id,
                        startedAt: Date(timeIntervalSince1970: 99),
                        dnsMs: 7,
                        connectMs: 11,
                        tlsMs: 16,
                        firstByteMs: 20,
                        totalMs: 56,
                        statusCode: 200,
                        success: true,
                        reusedConnection: false,
                        failure: nil),
                    latestDNS: nil)
            ],
            watchedTarget: nil,
            diagnosis: Diagnosis(
                layer: .unknown,
                scope: .none,
                severity: .healthy,
                title: "Healthy",
                summary: "All good."),
            isStale: false,
            overallScore: 1.0,
            medianLatencyMs: 56,
            jitterMs: 12,
            reliability: 1.0)

        let presentation = StatusPresentationBuilder.presentation(for: snapshot)

        XCTAssertEqual(presentation.targetRows.first?.statusText, "56 ms")
        XCTAssertNil(presentation.targetRows.first?.detailText)
        XCTAssertEqual(presentation.targetRows.first?.tone, .healthy)
    }

    func test_toolbarStateUsesPastMinuteAverageFill() {
        let snapshot = HealthSnapshot(
            generatedAt: Date(timeIntervalSince1970: 100),
            path: nil,
            layers: healthyLayers,
            controlTargets: [],
            watchedTarget: nil,
            diagnosis: Diagnosis(
                layer: .unknown,
                scope: .none,
                severity: .healthy,
                title: "Healthy",
                summary: "All good."),
            isStale: false,
            overallScore: 1.0,
            medianLatencyMs: 56,
            jitterMs: 12,
            reliability: 1.0)
        let history = HistorySnapshot(
            generatedAt: Date(timeIntervalSince1970: 100),
            window: .oneMinute,
            startDate: Date(timeIntervalSince1970: 40),
            endDate: Date(timeIntervalSince1970: 100),
            layerTimelines: [
                LayerTimeline(layer: .link, segments: [
                    LayerTimelineSegment(
                        startDate: Date(timeIntervalSince1970: 40),
                        endDate: Date(timeIntervalSince1970: 100),
                        status: .healthy)
                ]),
                LayerTimeline(layer: .dns, segments: [
                    LayerTimelineSegment(
                        startDate: Date(timeIntervalSince1970: 40),
                        endDate: Date(timeIntervalSince1970: 70),
                        status: .healthy),
                    LayerTimelineSegment(
                        startDate: Date(timeIntervalSince1970: 70),
                        endDate: Date(timeIntervalSince1970: 100),
                        status: .degraded)
                ]),
                LayerTimeline(layer: .internet, segments: [
                    LayerTimelineSegment(
                        startDate: Date(timeIntervalSince1970: 40),
                        endDate: Date(timeIntervalSince1970: 100),
                        status: .healthy)
                ]),
                LayerTimeline(layer: .quality, segments: [
                    LayerTimelineSegment(
                        startDate: Date(timeIntervalSince1970: 40),
                        endDate: Date(timeIntervalSince1970: 80),
                        status: .healthy),
                    LayerTimelineSegment(
                        startDate: Date(timeIntervalSince1970: 80),
                        endDate: Date(timeIntervalSince1970: 100),
                        status: .failed)
                ])
            ],
            pingTimeline: nil,
            jitterTimeline: nil,
            reliabilityTimeline: nil,
            metricBreakdowns: [])

        let toolbarState = StatusPresentationBuilder.toolbarState(for: snapshot, historySnapshot: history)

        XCTAssertEqual(toolbarState.bars[0], .healthy)
        XCTAssertEqual(toolbarState.bars[1].tone, .degraded)
        XCTAssertEqual(toolbarState.bars[1].fillFraction, 0.79, accuracy: 0.001)
        XCTAssertEqual(toolbarState.bars[3].tone, .degraded)
        XCTAssertEqual(toolbarState.bars[3].fillFraction, 0.6666666667, accuracy: 0.001)
        XCTAssertTrue(toolbarState.tooltip.contains("1m average"))
    }

    func test_failedTargetRowsKeepUsefulFailureContext() {
        let target = ProbeTarget(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            kind: .watched,
            name: "GitHub",
            url: URL(string: "https://github.com")!,
            method: .auto,
            interval: 15,
            timeout: 3.0)
        let snapshot = HealthSnapshot(
            generatedAt: Date(timeIntervalSince1970: 100),
            path: nil,
            layers: healthyLayers,
            controlTargets: [],
            watchedTarget: TargetHealth(
                id: target.id,
                target: target,
                medianLatencyMs: nil,
                jitterMs: nil,
                successRate: 0,
                lastFailureText: "Timeout",
                latestHTTP: HTTPProbeResult(
                    targetID: target.id,
                    startedAt: Date(timeIntervalSince1970: 99),
                    dnsMs: 7,
                    connectMs: 11,
                    tlsMs: nil,
                    firstByteMs: nil,
                    totalMs: 3000,
                    statusCode: nil,
                    success: false,
                    reusedConnection: false,
                    failure: .timeout),
                latestDNS: nil),
            diagnosis: Diagnosis(
                layer: .watchedService,
                scope: .targetSpecific,
                severity: .degraded,
                title: "Service-specific issue",
                summary: "GitHub is failing."),
            isStale: false,
            overallScore: 1.0,
            medianLatencyMs: 56,
            jitterMs: 12,
            reliability: 1.0)

        let presentation = StatusPresentationBuilder.presentation(for: snapshot)

        XCTAssertEqual(presentation.watchedTargetRow?.statusText, "Timeout")
        XCTAssertEqual(presentation.watchedTargetRow?.detailText, "0% success")
        XCTAssertEqual(presentation.watchedTargetRow?.tone, .failed)
    }

    private var healthyLayers: [LayerHealthSnapshot] {
        [
            LayerHealthSnapshot(
                layer: .link,
                status: .healthy,
                score: 1,
                title: "Link",
                explanation: "",
                primaryMetricText: "Wi-Fi"),
            LayerHealthSnapshot(
                layer: .dns,
                status: .healthy,
                score: 1,
                title: "DNS",
                explanation: "",
                primaryMetricText: "6 ms"),
            LayerHealthSnapshot(
                layer: .internet,
                status: .healthy,
                score: 1,
                title: "Internet",
                explanation: "",
                primaryMetricText: "56 ms"),
            LayerHealthSnapshot(
                layer: .quality,
                status: .healthy,
                score: 1,
                title: "Quality",
                explanation: "",
                primaryMetricText: "12 ms jitter")
        ]
    }
}
