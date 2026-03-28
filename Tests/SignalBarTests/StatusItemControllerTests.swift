import AppKit
@testable import SignalBar
import XCTest

@MainActor
final class StatusItemControllerTests: XCTestCase {
    func test_overviewCardMenuItemIsEnabledForInlineInteraction() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = HealthStore(sourceMode: .preview, userDefaults: defaults)
        let controller = StatusItemController(store: store)
        controller.menuWillOpen(controller.debugMenu)

        XCTAssertFalse(controller.debugMenu.items.isEmpty)
        XCTAssertTrue(controller.debugMenu.items[0].isEnabled)
        XCTAssertNotNil(controller.debugMenu.items[0].view)

        NSStatusBar.system.removeStatusItem(controller.debugStatusItem)
    }
}
