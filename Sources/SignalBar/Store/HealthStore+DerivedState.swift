import Foundation
import SignalBarCore

@MainActor
extension HealthStore {
    var toolbarState: ToolbarVisualState {
        switch sourceMode {
        case .livePath:
            StatusPresentationBuilder.toolbarState(for: liveSnapshot, historySnapshot: toolbarHistorySnapshot)
        case .preview:
            StatusPresentationBuilder.toolbarState(for: previewScenario.snapshot(updatedAt: previewUpdatedAt))
        }
    }

    var presentation: StatusPresentation {
        switch sourceMode {
        case .livePath:
            StatusPresentationBuilder.presentation(for: liveSnapshot)
        case .preview:
            StatusPresentationBuilder.presentation(for: previewScenario.snapshot(updatedAt: previewUpdatedAt))
        }
    }

    var layerRows: [LayerRowViewState] {
        presentation.layerRows
    }

    var isLiveDataStale: Bool {
        liveSnapshot?.isStale ?? false
    }

    var shouldRefreshOnMenuOpen: Bool {
        guard sourceMode == .livePath else { return false }
        guard !isPaused else { return false }
        guard let snapshot else { return true }
        return isLiveDataStale || snapshot.diagnosis.severity != .healthy
    }

    var historySnapshot: HistorySnapshot {
        switch sourceMode {
        case .livePath:
            liveHistorySnapshot ?? .placeholder(window: timelineWindow, at: updatedAt)
        case .preview:
            previewScenario.historySnapshot(window: timelineWindow, updatedAt: previewUpdatedAt)
        }
    }

    var updatedAt: Date {
        switch sourceMode {
        case .livePath:
            snapshot?.generatedAt ?? previewUpdatedAt
        case .preview:
            previewUpdatedAt
        }
    }

    private var liveSnapshot: HealthSnapshot? {
        freshnessPolicy.applying(to: snapshot, isPaused: isPaused, now: currentDate)
    }
}
