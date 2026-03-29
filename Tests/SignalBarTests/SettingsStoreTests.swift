@testable import SignalBar
import SignalBarCore
import XCTest

@MainActor
final class SettingsStoreTests: XCTestCase {
    func test_defaultsLoadExpectedValues() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = SettingsStore(userDefaults: defaults)

        XCTAssertEqual(store.displayMode, .segmentedPipeline)
        XCTAssertEqual(store.colorMode, .monochrome)
        XCTAssertEqual(store.timelineWindow, .oneMinute)
        XCTAssertEqual(store.historyMetric, .ping)
        XCTAssertNil(store.watchedTarget)
        XCTAssertFalse(store.isPaused)
        XCTAssertEqual(store.refreshCadenceProfile, .balanced)
        XCTAssertEqual(store.customRefreshCadenceIntervalSeconds, 15)
        XCTAssertTrue(store.lowPowerModeBackoffEnabled)
    }

    func test_changesPersistAcrossInstances() {
        let suiteName = "SettingsStoreTests-\(#function)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let watchedTarget = ProbeTarget(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            kind: .watched,
            name: "GitHub",
            url: URL(string: "https://github.com")!,
            method: .auto,
            interval: 15,
            timeout: 3.0)

        let first = SettingsStore(userDefaults: defaults)
        first.setDisplayMode(.semanticBars)
        first.setColorMode(.mutedAccent)
        first.setTimelineWindow(.sixtyMinutes)
        first.setHistoryMetric(.jitter)
        first.setWatchedTarget(watchedTarget)
        first.setPaused(true)
        first.setRefreshCadenceProfile(.custom)
        first.setCustomRefreshCadenceIntervalSeconds(27)
        first.setLowPowerModeBackoffEnabled(false)

        let second = SettingsStore(userDefaults: defaults)
        XCTAssertEqual(second.displayMode, .semanticBars)
        XCTAssertEqual(second.colorMode, .mutedAccent)
        XCTAssertEqual(second.timelineWindow, .sixtyMinutes)
        XCTAssertEqual(second.historyMetric, .jitter)
        XCTAssertEqual(second.watchedTarget?.name, "GitHub")
        XCTAssertTrue(second.isPaused)
        XCTAssertEqual(second.refreshCadenceProfile, .custom)
        XCTAssertEqual(second.customRefreshCadenceIntervalSeconds, 27)
        XCTAssertFalse(second.lowPowerModeBackoffEnabled)
    }
}
