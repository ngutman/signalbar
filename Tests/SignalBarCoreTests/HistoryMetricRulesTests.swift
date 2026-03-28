@testable import SignalBarCore
import XCTest

final class HistoryMetricRulesTests: XCTestCase {
    func test_pingThresholdsMatchExpectedBands() {
        XCTAssertEqual(HistoryMetricRules.qualityBand(for: .ping, value: nil), .unavailable)
        XCTAssertEqual(HistoryMetricRules.qualityBand(for: .ping, value: 45), .good)
        XCTAssertEqual(HistoryMetricRules.qualityBand(for: .ping, value: 80), .okay)
        XCTAssertEqual(HistoryMetricRules.qualityBand(for: .ping, value: 180), .degraded)
        XCTAssertEqual(HistoryMetricRules.qualityBand(for: .ping, value: 320), .bad)
    }

    func test_jitterThresholdsMatchExpectedBands() {
        XCTAssertEqual(HistoryMetricRules.qualityBand(for: .jitter, value: nil), .unavailable)
        XCTAssertEqual(HistoryMetricRules.qualityBand(for: .jitter, value: 10), .good)
        XCTAssertEqual(HistoryMetricRules.qualityBand(for: .jitter, value: 20), .okay)
        XCTAssertEqual(HistoryMetricRules.qualityBand(for: .jitter, value: 45), .degraded)
        XCTAssertEqual(HistoryMetricRules.qualityBand(for: .jitter, value: 80), .bad)
    }

    func test_reliabilityThresholdsMatchExpectedBands() {
        XCTAssertEqual(HistoryMetricRules.qualityBand(for: .reliability, value: nil), .unavailable)
        XCTAssertEqual(HistoryMetricRules.qualityBand(for: .reliability, value: 99), .good)
        XCTAssertEqual(HistoryMetricRules.qualityBand(for: .reliability, value: 96), .okay)
        XCTAssertEqual(HistoryMetricRules.qualityBand(for: .reliability, value: 85), .degraded)
        XCTAssertEqual(HistoryMetricRules.qualityBand(for: .reliability, value: 60), .bad)
    }

    func test_upperBoundsUseExpectedFloorAndRounding() {
        XCTAssertEqual(HistoryMetricRules.upperBound(for: .ping, maxValue: 0), 300)
        XCTAssertEqual(HistoryMetricRules.upperBound(for: .ping, maxValue: 333), 400)
        XCTAssertEqual(HistoryMetricRules.upperBound(for: .jitter, maxValue: 0), 80)
        XCTAssertEqual(HistoryMetricRules.upperBound(for: .jitter, maxValue: 83), 100)
        XCTAssertEqual(HistoryMetricRules.upperBound(for: .reliability, maxValue: 55), 100)
        XCTAssertEqual(HistoryMetricRules.upperBound(for: .overview, maxValue: 55), 1)
    }
}
