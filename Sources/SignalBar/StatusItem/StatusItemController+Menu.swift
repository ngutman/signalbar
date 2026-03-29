import AppKit
import SwiftUI

@MainActor
extension StatusItemController {
    func rebuildMenu() {
        menu.removeAllItems()

        menu.addItem(makeOverviewCardItem())
        menu.addItem(.separator())

        let refreshItem = NSMenuItem(title: "Refresh now", action: #selector(refreshNow), keyEquivalent: "")
        refreshItem.target = self
        menu.addItem(refreshItem)

        let pauseItem = NSMenuItem(
            title: store.isPaused ? "Resume probing" : "Pause probing",
            action: #selector(togglePauseProbing),
            keyEquivalent: "")
        pauseItem.target = self
        menu.addItem(pauseItem)

        let copyItem = NSMenuItem(
            title: "Copy diagnostic summary",
            action: #selector(copyDiagnosticSummary),
            keyEquivalent: "")
        copyItem.target = self
        menu.addItem(copyItem)

        menu.addItem(.separator())

        let optionsItem = NSMenuItem(title: "Options", action: nil, keyEquivalent: "")
        optionsItem.submenu = makeOptionsMenu()
        menu.addItem(optionsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    func makeOverviewCardItem() -> NSMenuItem {
        makeMenuCardItem(
            MenuOverviewCardView(store: store, width: Self.menuCardWidth),
            width: Self.menuCardWidth)
    }

    func makeMenuCardItem(_ view: some View, width: CGFloat) -> NSMenuItem {
        let item = NSMenuItem()
        let hostingView = MenuCardHostingView(rootView: AnyView(view))
        hostingView.menuWidth = width
        hostingView.frame = NSRect(x: 0, y: 0, width: width, height: 10)
        hostingView.layoutSubtreeIfNeeded()
        hostingView.applyMeasuredHeight(hostingView.fittingSize.height, width: width)
        item.view = hostingView
        item.isEnabled = true
        return item
    }

    func makeOptionsMenu() -> NSMenu {
        let menu = NSMenu(title: "Options")

        let appearanceItem = NSMenuItem(title: "Appearance", action: nil, keyEquivalent: "")
        appearanceItem.submenu = makeAppearanceMenu()
        menu.addItem(appearanceItem)

        let watchedTargetItem = NSMenuItem(title: "Watched target", action: nil, keyEquivalent: "")
        watchedTargetItem.submenu = makeWatchedTargetMenu()
        menu.addItem(watchedTargetItem)

        return menu
    }

    func makeAppearanceMenu() -> NSMenu {
        let menu = NSMenu(title: "Appearance")

        let displayModeItem = NSMenuItem(title: "Toolbar icon", action: nil, keyEquivalent: "")
        displayModeItem.submenu = makeDisplayModeMenu()
        menu.addItem(displayModeItem)

        let colorModeItem = NSMenuItem(title: "Color style", action: nil, keyEquivalent: "")
        colorModeItem.submenu = makeColorModeMenu()
        menu.addItem(colorModeItem)

        return menu
    }

    func makeDisplayModeMenu() -> NSMenu {
        let menu = NSMenu(title: "Toolbar icon")
        for displayMode in MenuBarDisplayMode.allCases {
            let item = NSMenuItem(
                title: displayMode.displayName,
                action: #selector(selectDisplayMode(_:)),
                keyEquivalent: "")
            item.target = self
            item.representedObject = displayMode.rawValue
            item.state = displayMode == store.displayMode ? .on : .off
            menu.addItem(item)
        }
        return menu
    }

    func makeColorModeMenu() -> NSMenu {
        let menu = NSMenu(title: "Color style")
        for colorMode in MenuBarColorMode.allCases {
            let item = NSMenuItem(
                title: colorMode.displayName,
                action: #selector(selectColorMode(_:)),
                keyEquivalent: "")
            item.target = self
            item.representedObject = colorMode.rawValue
            item.state = colorMode == store.colorMode ? .on : .off
            menu.addItem(item)
        }
        return menu
    }

    func makeWatchedTargetMenu() -> NSMenu {
        let menu = NSMenu(title: "Watched target")
        let addTitle = store.watchedTarget == nil ? "Add watched target…" : "Edit watched target…"
        let addItem = NSMenuItem(title: addTitle, action: #selector(configureWatchedTarget), keyEquivalent: "")
        addItem.target = self
        menu.addItem(addItem)

        let removeItem = NSMenuItem(
            title: "Remove watched target",
            action: #selector(removeWatchedTarget),
            keyEquivalent: "")
        removeItem.target = self
        removeItem.isEnabled = store.watchedTarget != nil
        menu.addItem(removeItem)
        return menu
    }
}

private final class MenuCardHostingView: NSHostingView<AnyView> {
    var menuWidth: CGFloat = 0
    private var isApplyingMeasuredHeight = false

    override var allowsVibrancy: Bool {
        true
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func layout() {
        super.layout()

        guard !isApplyingMeasuredHeight, menuWidth > 0 else { return }
        applyMeasuredHeight(fittingSize.height, width: menuWidth)
    }

    func applyMeasuredHeight(_ height: CGFloat, width: CGFloat) {
        let targetHeight = ceil(max(1, height))
        guard abs(frame.width - width) > 0.5 || abs(frame.height - targetHeight) > 0.5 else {
            return
        }

        isApplyingMeasuredHeight = true
        defer { isApplyingMeasuredHeight = false }

        frame = NSRect(x: 0, y: 0, width: width, height: targetHeight)
        invalidateIntrinsicContentSize()
        superview?.needsLayout = true
        superview?.layoutSubtreeIfNeeded()
        window?.contentView?.needsLayout = true
        window?.contentView?.layoutSubtreeIfNeeded()
        enclosingMenuItem?.menu?.update()
    }
}
