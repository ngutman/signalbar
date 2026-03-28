import Foundation
import SignalBarCore

enum ToolbarVisualStateBuilder {
    static func toolbarState(for snapshot: HealthSnapshot?,
                             historySnapshot: HistorySnapshot? = nil) -> ToolbarVisualState
    {
        guard let snapshot else {
            return ToolbarVisualState(
                bars: [.pending, .pending, .pending, .pending],
                overlay: .none,
                isDimmed: false,
                tooltip: "SignalBar — starting · waiting for initial network path state",
                accessibilityLabel: "SignalBar. Waiting for initial network path state.")
        }

        let bars = HealthLayer.allCases.map { layer in
            toolbarBarState(for: layer, snapshot: snapshot, historySnapshot: historySnapshot)
        }
        let overlay: ToolbarOverlay = {
            if snapshot.diagnosis.severity == .offline {
                return .offlineSlash
            }
            if snapshot.diagnosis.layer == .watchedService {
                return .watchedTargetBadge
            }
            return .none
        }()
        return ToolbarVisualState(
            bars: bars,
            overlay: overlay,
            isDimmed: snapshot.isStale,
            tooltip: tooltip(for: snapshot, historySnapshot: historySnapshot),
            accessibilityLabel: accessibilityLabel(for: snapshot, historySnapshot: historySnapshot))
    }

    private static func toolbarBarState(
        for layer: HealthLayer,
        snapshot: HealthSnapshot,
        historySnapshot: HistorySnapshot?) -> ToolbarBarVisualState
    {
        if let historySnapshot,
           let averagedState = averagedToolbarBarState(for: layer, historySnapshot: historySnapshot)
        {
            return averagedState
        }

        let status = snapshot.layers.first(where: { $0.layer == layer })?.status ?? .pending
        return discreteToolbarBarState(for: status)
    }

    private static func averagedToolbarBarState(for layer: HealthLayer,
                                                historySnapshot: HistorySnapshot) -> ToolbarBarVisualState?
    {
        guard let timeline = historySnapshot.layerTimelines.first(where: { $0.layer == layer }) else {
            return nil
        }
        let totalDuration = historySnapshot.endDate.timeIntervalSince(historySnapshot.startDate)
        guard totalDuration > 0 else { return nil }

        var weightedFill: Double = 0
        var pendingDuration: TimeInterval = 0
        var unavailableDuration: TimeInterval = 0

        for segment in timeline.segments {
            let duration = max(0, segment.endDate.timeIntervalSince(segment.startDate))
            weightedFill += duration * fillFraction(for: segment.status)
            if segment.status == .pending {
                pendingDuration += duration
            }
            if segment.status == .unavailable {
                unavailableDuration += duration
            }
        }

        let averageFill = max(0, min(1, weightedFill / totalDuration))
        let tone: ToolbarBarTone = if pendingDuration / totalDuration >= 0.66 {
            .pending
        } else if unavailableDuration / totalDuration >= 0.66 {
            .unavailable
        } else if averageFill >= 0.92 {
            .healthy
        } else if averageFill >= 0.45 {
            .degraded
        } else {
            .failed
        }

        return ToolbarBarVisualState(tone: tone, fillFraction: averageFill)
    }

    private static func discreteToolbarBarState(for status: LayerStatus) -> ToolbarBarVisualState {
        switch status {
        case .healthy:
            .healthy
        case .degraded:
            .degraded
        case .failed:
            .failed
        case .pending:
            .pending
        case .unavailable:
            .unavailable
        }
    }

    private static func fillFraction(for status: LayerStatus) -> Double {
        switch status {
        case .healthy:
            1.0
        case .degraded:
            0.58
        case .pending:
            0.28
        case .failed, .unavailable:
            0.0
        }
    }

    private static func tooltip(for snapshot: HealthSnapshot, historySnapshot: HistorySnapshot?) -> String {
        let barDescriptions = HealthLayer.allCases.compactMap { layer -> String? in
            guard let layerSnapshot = snapshot.layers.first(where: { $0.layer == layer }) else { return nil }
            return "\(layer.displayName.lowercased()) \(layerSnapshot.status.displayName.lowercased())"
        }
        let prefix = snapshot.path?.interface?.displayName ?? "network"
        let averageSuffix = historySnapshot == nil ? "" : " · icon shows 1m average"
        let watchedSuffix: String = {
            guard snapshot.diagnosis.layer == .watchedService,
                  let watchedTarget = snapshot.watchedTarget
            else { return "" }
            return " · watched target \(watchedTarget.target.name) failing"
        }()
        return "SignalBar — \(prefix) · \(barDescriptions.joined(separator: " · "))\(averageSuffix)\(watchedSuffix)"
    }

    private static func accessibilityLabel(for snapshot: HealthSnapshot, historySnapshot: HistorySnapshot?) -> String {
        let components = HealthLayer.allCases.compactMap { layer -> String? in
            guard let layerSnapshot = snapshot.layers.first(where: { $0.layer == layer }) else { return nil }
            return "\(layer.displayName) \(layerSnapshot.status.displayName.lowercased())"
        }
        let averageSuffix = historySnapshot == nil ? "" : " Toolbar icon reflects the past minute average."
        let watchedSuffix: String = {
            guard snapshot.diagnosis.layer == .watchedService,
                  let watchedTarget = snapshot.watchedTarget
            else { return "" }
            return " Watched target \(watchedTarget.target.name) failing."
        }()
        return "SignalBar. \(components.joined(separator: ". ")).\(averageSuffix)\(watchedSuffix)"
    }
}
