import Foundation
import Observation

@MainActor
@Observable
final class SettingsSelection {
    var tab: SettingsTab = .general
}

enum SettingsTab: String, CaseIterable, Hashable, Identifiable {
    case general
    case display
    case targets
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general:
            "General"
        case .display:
            "Display"
        case .targets:
            "Targets"
        case .about:
            "About"
        }
    }

    var systemImage: String {
        switch self {
        case .general:
            "gearshape"
        case .display:
            "eye"
        case .targets:
            "target"
        case .about:
            "info.circle"
        }
    }
}
