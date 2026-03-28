@testable import SignalBar
import XCTest

final class PreviewScenarioTests: XCTestCase {
    func test_previewPresentationUsesDerivedWatchedTargetRow() {
        let presentation = PreviewScenario.watchedServiceIssue.presentation

        XCTAssertEqual(presentation.titleText, "Service-specific issue")
        XCTAssertEqual(presentation.watchedTargetRow?.labelText, "Watched · GitHub")
        XCTAssertEqual(presentation.watchedTargetRow?.statusText, "Timeout")
        XCTAssertEqual(presentation.watchedTargetRow?.detailText, "0% success")
    }

    func test_offlineScenarioUsesOfflineSlashAndUnavailableDownstreamBars() {
        let state = PreviewScenario.offline.toolbarState

        XCTAssertEqual(state.overlay, .offlineSlash)
        XCTAssertEqual(state.bars, [.failed, .unavailable, .unavailable, .unavailable])
    }

    func test_watchedServiceScenarioUsesBadgeWithoutBreakingCoreBars() {
        let state = PreviewScenario.watchedServiceIssue.toolbarState

        XCTAssertEqual(state.overlay, .watchedTargetBadge)
        XCTAssertEqual(state.bars, [.healthy, .healthy, .healthy, .healthy])
        XCTAssertFalse(state.isDimmed)
    }
}
