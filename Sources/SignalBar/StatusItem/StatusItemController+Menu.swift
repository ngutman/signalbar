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

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.keyEquivalentModifierMask = [.command]
        settingsItem.target = self
        menu.addItem(settingsItem)

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
