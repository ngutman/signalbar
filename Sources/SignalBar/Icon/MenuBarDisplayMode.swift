import Foundation

enum MenuBarDisplayMode: String, CaseIterable, Sendable {
    case semanticBars
    case segmentedPipeline

    var displayName: String {
        switch self {
        case .semanticBars:
            "Semantic bars"
        case .segmentedPipeline:
            "Segmented pipeline"
        }
    }

    var detailText: String {
        switch self {
        case .semanticBars:
            "Ascending bars, one per layer."
        case .segmentedPipeline:
            "Equal-height segments, easier to spot the affected layer."
        }
    }

    static var defaultValue: MenuBarDisplayMode {
        .semanticBars
    }
}
