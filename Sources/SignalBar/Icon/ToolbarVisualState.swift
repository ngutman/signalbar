import Foundation

enum ToolbarBarTone: Sendable, Equatable {
    case healthy
    case degraded
    case failed
    case pending
    case unavailable
}

struct ToolbarBarVisualState: Sendable, Equatable {
    let tone: ToolbarBarTone
    let fillFraction: Double

    init(tone: ToolbarBarTone, fillFraction: Double) {
        self.tone = tone
        self.fillFraction = min(max(fillFraction, 0), 1)
    }

    static let healthy = Self(tone: .healthy, fillFraction: 1.0)
    static let degraded = Self(tone: .degraded, fillFraction: 0.58)
    static let failed = Self(tone: .failed, fillFraction: 0.0)
    static let pending = Self(tone: .pending, fillFraction: 0.28)
    static let unavailable = Self(tone: .unavailable, fillFraction: 0.0)
}

enum ToolbarOverlay: Sendable, Equatable {
    case none
    case offlineSlash
    case watchedTargetBadge
}

struct ToolbarVisualState: Sendable, Equatable {
    let bars: [ToolbarBarVisualState]
    let overlay: ToolbarOverlay
    let isDimmed: Bool
    let tooltip: String
    let accessibilityLabel: String

    init(
        bars: [ToolbarBarVisualState],
        overlay: ToolbarOverlay,
        isDimmed: Bool,
        tooltip: String,
        accessibilityLabel: String)
    {
        precondition(bars.count == 4, "ToolbarVisualState must contain exactly four semantic bars.")
        self.bars = bars
        self.overlay = overlay
        self.isDimmed = isDimmed
        self.tooltip = tooltip
        self.accessibilityLabel = accessibilityLabel
    }
}
