import AppKit
import Observation
import SignalBarCore

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    static let menuCardWidth: CGFloat = 456

    let store: HealthStore
    private let statusBar: NSStatusBar
    lazy var statusItem: NSStatusItem = {
        let item = self.statusBar.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.imageScaling = .scaleNone
        item.button?.imagePosition = .imageOnly
        return item
    }()

    lazy var menu: NSMenu = {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self
        return menu
    }()

    init(store: HealthStore, statusBar: NSStatusBar = .system) {
        self.store = store
        self.statusBar = statusBar
        super.init()
        rebuildMenu()
        statusItem.menu = menu
        observeStore()
        updateStatusItem()
    }

    private func observeStore() {
        withObservationTracking {
            _ = self.store.watchedTarget
            _ = self.store.snapshot
            _ = self.store.toolbarHistorySnapshot
            _ = self.store.currentDate
            _ = self.store.updatedAt
            _ = self.store.isPaused
            _ = self.store.displayMode
            _ = self.store.colorMode
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                observeStore()
                updateStatusItem()
            }
        }
    }

    private func updateStatusItem() {
        let toolbarState = store.toolbarState
        statusItem.button?.image = IconRenderer.makeIcon(
            state: toolbarState,
            displayMode: store.displayMode,
            colorMode: store.colorMode)
        statusItem.button?.toolTip = toolbarState.tooltip
        if statusItem.menu == nil {
            statusItem.menu = menu
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        guard menu === self.menu else { return }
        rebuildMenu()
        if store.shouldRefreshOnMenuOpen {
            store.refreshNow()
        }
    }

    #if DEBUG
    var debugMenu: NSMenu {
        menu
    }

    var debugStatusItem: NSStatusItem {
        statusItem
    }
    #endif
}
