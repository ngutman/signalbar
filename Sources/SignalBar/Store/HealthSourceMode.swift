import Foundation

enum HealthSourceMode: String, CaseIterable, Sendable {
    case livePath
    case preview

    var displayName: String {
        switch self {
        case .livePath:
            "Live path"
        case .preview:
            "Preview"
        }
    }

    var detailText: String {
        switch self {
        case .livePath:
            "Use the real macOS network path state from NWPathMonitor."
        case .preview:
            "Use fake scenarios to validate icon and menu behavior."
        }
    }

    static var defaultValue: HealthSourceMode {
        .livePath
    }
}
