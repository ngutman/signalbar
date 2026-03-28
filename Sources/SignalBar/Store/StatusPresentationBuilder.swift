import SignalBarCore

enum StatusPresentationBuilder {
    static func toolbarState(for snapshot: HealthSnapshot?,
                             historySnapshot: HistorySnapshot? = nil) -> ToolbarVisualState
    {
        ToolbarVisualStateBuilder.toolbarState(for: snapshot, historySnapshot: historySnapshot)
    }

    static func presentation(for snapshot: HealthSnapshot?) -> StatusPresentation {
        MenuPresentationBuilder.presentation(for: snapshot)
    }
}
