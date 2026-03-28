import Foundation

enum MenuBarColorMode: String, CaseIterable, Sendable {
    case monochrome
    case mutedAccent

    var displayName: String {
        switch self {
        case .monochrome:
            "Monochrome"
        case .mutedAccent:
            "Muted accents"
        }
    }

    var detailText: String {
        switch self {
        case .monochrome:
            "System-style monochrome icon that blends into the menu bar."
        case .mutedAccent:
            "Keep healthy layers neutral and softly color only degraded or failed layers."
        }
    }

    static var defaultValue: MenuBarColorMode {
        .monochrome
    }
}
