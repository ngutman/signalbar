import Foundation

enum DiagnosticSummaryBuilder {
    static func summary(for presentation: StatusPresentation) -> String {
        "SignalBar: \(presentation.titleText). \(presentation.summaryText). \(presentation.contextText)."
    }
}
