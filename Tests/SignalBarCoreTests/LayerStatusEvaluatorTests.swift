@testable import SignalBarCore
import XCTest

final class LayerStatusEvaluatorTests: XCTestCase {
    func test_dnsThresholdsMapToExpectedStatuses() {
        XCTAssertEqual(LayerStatusEvaluator.dnsLayerStatus(successRate: 0, medianLatencyMs: nil), .failed)
        XCTAssertEqual(LayerStatusEvaluator.dnsLayerStatus(successRate: 0.8, medianLatencyMs: 40), .degraded)
        XCTAssertEqual(LayerStatusEvaluator.dnsLayerStatus(successRate: 1.0, medianLatencyMs: 180), .degraded)
        XCTAssertEqual(LayerStatusEvaluator.dnsLayerStatus(successRate: 1.0, medianLatencyMs: 20), .healthy)
    }

    func test_qualityThresholdsRespectPendingAndUnavailable() {
        XCTAssertEqual(
            LayerStatusEvaluator
                .qualityLayerStatus(successRate: 1, medianLatencyMs: nil, jitterMs: nil, hasHTTPSamples: false),
            .pending)
        XCTAssertEqual(
            LayerStatusEvaluator
                .qualityLayerStatus(successRate: 0, medianLatencyMs: nil, jitterMs: nil, hasHTTPSamples: true),
            .unavailable)
        XCTAssertEqual(
            LayerStatusEvaluator
                .qualityLayerStatus(successRate: 1, medianLatencyMs: 550, jitterMs: nil, hasHTTPSamples: true),
            .failed)
        XCTAssertEqual(
            LayerStatusEvaluator
                .qualityLayerStatus(successRate: 1, medianLatencyMs: 120, jitterMs: 80, hasHTTPSamples: true),
            .degraded)
    }
}
