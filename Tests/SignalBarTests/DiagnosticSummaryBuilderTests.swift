@testable import SignalBar
import XCTest

final class DiagnosticSummaryBuilderTests: XCTestCase {
    func test_summaryIncludesTitleSummaryAndContext() {
        let presentation = StatusPresentation(
            titleText: "Healthy",
            summaryText: "Internet path looks normal",
            contextText: "Wi-Fi · IPv4/IPv6",
            layerRows: [],
            targetRows: [],
            watchedTargetRow: nil)

        XCTAssertEqual(
            DiagnosticSummaryBuilder.summary(for: presentation),
            "SignalBar: Healthy. Internet path looks normal. Wi-Fi · IPv4/IPv6.")
    }
}
