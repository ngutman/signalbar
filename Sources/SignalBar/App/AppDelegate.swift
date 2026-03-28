import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var healthStore: HealthStore?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let store = HealthStore()
        store.start()
        healthStore = store
        statusItemController = StatusItemController(store: store)
    }
}
