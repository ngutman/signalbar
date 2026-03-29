import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var healthStore: HealthStore?
    private var statusItemController: StatusItemController?
    private var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let store = HealthStore()
        store.start()
        healthStore = store
        settingsWindowController = SettingsWindowController(store: store)
        statusItemController = StatusItemController(store: store) { [weak self] in
            self?.openSettings()
        }
    }

    private func openSettings(tab: SettingsTab = .general) {
        settingsWindowController?.show(tab: tab)
    }
}
