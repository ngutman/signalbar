@testable import SignalBar
import SignalBarCore
import XCTest

final class HistoryModeDisplayLogicTests: XCTestCase {
    func test_targetsCardShownOnlyInOverview() {
        XCTAssertTrue(HistoryModeDisplayLogic.shouldShowTargetsCard(selectedMetric: .overview, targetCount: 1))
        XCTAssertFalse(HistoryModeDisplayLogic.shouldShowTargetsCard(selectedMetric: .ping, targetCount: 1))
        XCTAssertFalse(HistoryModeDisplayLogic.shouldShowTargetsCard(selectedMetric: .jitter, targetCount: 1))
        XCTAssertFalse(HistoryModeDisplayLogic.shouldShowTargetsCard(selectedMetric: .reliability, targetCount: 1))
        XCTAssertFalse(HistoryModeDisplayLogic.shouldShowTargetsCard(selectedMetric: .overview, targetCount: 0))
    }

    func test_reliabilityContributionSummarySeparatesHealthyDegradedFailingAndUnavailable() {
        let contributions: [MetricBucketContribution] = [
            .init(label: "Apple", value: 100, unitText: "%", qualityBand: .good, hadFailure: false, failureText: nil),
            .init(
                label: "Cloudflare",
                value: 94,
                unitText: "%",
                qualityBand: .degraded,
                hadFailure: false,
                failureText: nil),
            .init(
                label: "Google",
                value: 0,
                unitText: "%",
                qualityBand: .bad,
                hadFailure: true,
                failureText: "Timeout"),
            .init(
                label: "GitHub",
                value: nil,
                unitText: "%",
                qualityBand: .unavailable,
                hadFailure: false,
                failureText: nil)
        ]

        let summary = HistoryModeDisplayLogic.reliabilityContributionSummary(for: contributions)

        XCTAssertEqual(summary.healthyCount, 1)
        XCTAssertEqual(summary.degradedCount, 1)
        XCTAssertEqual(summary.failingCount, 1)
        XCTAssertEqual(summary.unavailableCount, 1)
        XCTAssertEqual(summary.totalCount, 4)
        XCTAssertTrue(summary.hasIssues)
    }

    func test_reliabilityIssueContributionsExcludeHealthyAndUnavailable() {
        let contributions: [MetricBucketContribution] = [
            .init(label: "Apple", value: 100, unitText: "%", qualityBand: .good, hadFailure: false, failureText: nil),
            .init(
                label: "Cloudflare",
                value: 97,
                unitText: "%",
                qualityBand: .okay,
                hadFailure: false,
                failureText: nil),
            .init(
                label: "GitHub",
                value: 0,
                unitText: "%",
                qualityBand: .bad,
                hadFailure: true,
                failureText: "Timeout"),
            .init(
                label: "Google",
                value: nil,
                unitText: "%",
                qualityBand: .unavailable,
                hadFailure: false,
                failureText: nil)
        ]

        let issues = HistoryModeDisplayLogic.reliabilityIssueContributions(from: contributions)

        XCTAssertEqual(issues.map(\.label), ["GitHub", "Cloudflare"])
    }
}
