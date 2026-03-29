import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private let store: HealthStore
    private let selection: SettingsSelection

    init(store: HealthStore, selection: SettingsSelection = SettingsSelection()) {
        self.store = store
        self.selection = selection

        let hostingController = NSHostingController(rootView: SettingsView(store: store, selection: selection))
        let window = NSWindow(contentViewController: hostingController)
        window.title = "SignalBar Settings"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(
            width: SettingsView.preferredContentSize.width,
            height: SettingsView.preferredContentSize.height))
        window.minSize = NSSize(
            width: SettingsView.preferredContentSize.width,
            height: SettingsView.preferredContentSize.height)
        window.center()
        window.isReleasedWhenClosed = false
        window.toolbarStyle = .preference
        window.setFrameAutosaveName("SignalBarSettingsWindow")

        super.init(window: window)
        window.delegate = self
        shouldCascadeWindows = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(tab: SettingsTab = .general) {
        selection.tab = tab
        store.refreshLaunchAtLoginState()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowDidBecomeKey(_ notification: Notification) {
        store.refreshLaunchAtLoginState()
    }
}
