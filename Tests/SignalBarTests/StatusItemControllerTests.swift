import AppKit
@testable import SignalBar
import XCTest

@MainActor
final class StatusItemControllerTests: XCTestCase {
    func test_overviewCardMenuItemIsEnabledForInlineInteraction() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = HealthStore(userDefaults: defaults)
        let controller = StatusItemController(store: store)
        controller.menuWillOpen(controller.debugMenu)

        XCTAssertFalse(controller.debugMenu.items.isEmpty)
        XCTAssertTrue(controller.debugMenu.items[0].isEnabled)
        XCTAssertNotNil(controller.debugMenu.items[0].view)

        NSStatusBar.system.removeStatusItem(controller.debugStatusItem)
    }

    func test_settingsMenuItemInvokesHandler() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = HealthStore(userDefaults: defaults)
        var didOpenSettings = false
        let controller = StatusItemController(store: store) {
            didOpenSettings = true
        }
        controller.menuWillOpen(controller.debugMenu)

        XCTAssertTrue(controller.debugMenu.items.contains(where: { $0.title == "Settings…" }))
        controller.openSettings()
        XCTAssertTrue(didOpenSettings)

        NSStatusBar.system.removeStatusItem(controller.debugStatusItem)
    }

    func test_menuCardResizesWhenHistoryMetricChanges() throws {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = HealthStore(sourceMode: .preview, userDefaults: defaults)
        store.setPreviewScenario(.internetFailure)
        store.setHistoryMetric(.reliability)

        let controller = StatusItemController(store: store)
        controller.menuWillOpen(controller.debugMenu)

        let cardView = try XCTUnwrap(controller.debugMenu.items.first?.view)
        let reliabilityHeight = cardView.frame.height
        XCTAssertEqual(reliabilityHeight, cardView.fittingSize.height, accuracy: 1)

        store.setHistoryMetric(.ping)
        pumpRunLoop()
        cardView.layoutSubtreeIfNeeded()

        let pingHeight = cardView.frame.height
        XCTAssertEqual(pingHeight, cardView.fittingSize.height, accuracy: 1)
        XCTAssertGreaterThan(abs(reliabilityHeight - pingHeight), 1)

        NSStatusBar.system.removeStatusItem(controller.debugStatusItem)
    }

    private func pumpRunLoop() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }
}
