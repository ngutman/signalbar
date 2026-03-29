@testable import SignalBar
import SignalBarCore
import XCTest

@MainActor
final class HealthStoreTests: XCTestCase {
    func test_sourceModeDefaultsToLivePath() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = HealthStore(userDefaults: defaults)

        XCTAssertEqual(store.sourceMode, .livePath)
    }

    func test_watchedTargetDefaultsToNil() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = HealthStore(userDefaults: defaults)

        XCTAssertNil(store.watchedTarget)
    }

    func test_watchedTargetPersistsAcrossStoreInstances() {
        let suiteName = "HealthStoreTests-\(#function)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let watchedTarget = ProbeTarget(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            kind: .watched,
            name: "GitHub",
            url: URL(string: "https://github.com")!,
            method: .auto,
            interval: 15,
            timeout: 3.0)

        let firstStore = HealthStore(userDefaults: defaults)
        firstStore.setWatchedTarget(watchedTarget)

        let secondStore = HealthStore(userDefaults: defaults)
        XCTAssertEqual(secondStore.watchedTarget?.name, "GitHub")
        XCTAssertEqual(secondStore.watchedTarget?.url.absoluteString, "https://github.com")
    }

    func test_historyMetricDefaultsToPing() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = HealthStore(userDefaults: defaults)

        XCTAssertEqual(store.historyMetric, .ping)
    }

    func test_historyMetricPersistsAcrossStoreInstances() {
        let suiteName = "HealthStoreTests-\(#function)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let firstStore = HealthStore(userDefaults: defaults)
        firstStore.setHistoryMetric(.jitter)

        let secondStore = HealthStore(userDefaults: defaults)
        XCTAssertEqual(secondStore.historyMetric, .jitter)
    }

    func test_timelineWindowDefaultsToOneMinute() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = HealthStore(userDefaults: defaults)

        XCTAssertEqual(store.timelineWindow, .oneMinute)
    }

    func test_timelineWindowPersistsAcrossStoreInstances() {
        let suiteName = "HealthStoreTests-\(#function)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let firstStore = HealthStore(userDefaults: defaults)
        firstStore.setTimelineWindow(.sixtyMinutes)

        let secondStore = HealthStore(userDefaults: defaults)
        XCTAssertEqual(secondStore.timelineWindow, .sixtyMinutes)
    }

    func test_displayModeDefaultsToSegmentedLines() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = HealthStore(userDefaults: defaults)

        XCTAssertEqual(store.displayMode, .segmentedPipeline)
    }

    func test_displayModePersistsAcrossStoreInstances() {
        let suiteName = "HealthStoreTests-\(#function)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let firstStore = HealthStore(userDefaults: defaults)
        firstStore.setDisplayMode(.segmentedPipeline)

        let secondStore = HealthStore(userDefaults: defaults)
        XCTAssertEqual(secondStore.displayMode, .segmentedPipeline)
    }

    func test_colorModeDefaultsToMonochrome() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = HealthStore(userDefaults: defaults)

        XCTAssertEqual(store.colorMode, .monochrome)
    }

    func test_colorModePersistsAcrossStoreInstances() {
        let suiteName = "HealthStoreTests-\(#function)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let firstStore = HealthStore(userDefaults: defaults)
        firstStore.setColorMode(.mutedAccent)

        let secondStore = HealthStore(userDefaults: defaults)
        XCTAssertEqual(secondStore.colorMode, .mutedAccent)
    }

    func test_pausedDefaultsToFalse() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = HealthStore(userDefaults: defaults)

        XCTAssertFalse(store.isPaused)
    }

    func test_pausedStatePersistsAcrossStoreInstances() {
        let suiteName = "HealthStoreTests-\(#function)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let firstStore = HealthStore(userDefaults: defaults)
        firstStore.pause()

        let secondStore = HealthStore(userDefaults: defaults)
        XCTAssertTrue(secondStore.isPaused)
    }

    func test_toolbarStateDimsWhenLiveSnapshotIsPastFreshnessThreshold() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let referenceDate = Date(timeIntervalSince1970: 2000)
        let store = HealthStore(updatedAt: referenceDate, userDefaults: defaults)
        store.snapshot = liveSnapshot(generatedAt: referenceDate.addingTimeInterval(-40))
        store.currentDate = referenceDate

        XCTAssertTrue(store.isLiveDataStale)
        XCTAssertTrue(store.toolbarState.isDimmed)
    }

    func test_shouldRefreshOnMenuOpenIsDisabledWhilePaused() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let referenceDate = Date(timeIntervalSince1970: 2000)
        let store = HealthStore(updatedAt: referenceDate, isPaused: true, userDefaults: defaults)
        store.snapshot = liveSnapshot(generatedAt: referenceDate.addingTimeInterval(-40))
        store.currentDate = referenceDate

        XCTAssertFalse(store.shouldRefreshOnMenuOpen)
        XCTAssertTrue(store.toolbarState.isDimmed)
    }

    private func liveSnapshot(generatedAt: Date) -> HealthSnapshot {
        let path = PathSnapshot(
            observedAt: generatedAt,
            status: .satisfied,
            interface: .wifi,
            isConstrained: false,
            isExpensive: false,
            supportsDNS: true,
            supportsIPv4: true,
            supportsIPv6: true)
        let layers = [
            LayerHealthSnapshot(
                layer: .link,
                status: .healthy,
                score: 1,
                title: "Link healthy",
                explanation: "Connected",
                primaryMetricText: "Wi-Fi"),
            LayerHealthSnapshot(
                layer: .dns,
                status: .healthy,
                score: 1,
                title: "DNS healthy",
                explanation: "Resolving",
                primaryMetricText: "12 ms"),
            LayerHealthSnapshot(
                layer: .internet,
                status: .healthy,
                score: 1,
                title: "Internet healthy",
                explanation: "Reachable",
                primaryMetricText: "99% success"),
            LayerHealthSnapshot(
                layer: .quality,
                status: .healthy,
                score: 1,
                title: "Quality healthy",
                explanation: "Stable",
                primaryMetricText: "14 ms jitter")
        ]
        return HealthSnapshot(
            generatedAt: generatedAt,
            path: path,
            layers: layers,
            controlTargets: [],
            watchedTarget: nil,
            diagnosis: Diagnosis(
                layer: .quality,
                scope: .none,
                severity: .healthy,
                title: "Healthy",
                summary: "Internet path looks normal"),
            isStale: false,
            overallScore: 1,
            medianLatencyMs: 22,
            jitterMs: 14,
            reliability: 1)
    }
}
