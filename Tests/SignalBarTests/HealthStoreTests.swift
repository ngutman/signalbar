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

    func test_launchAtLoginStateDefaultsFromInjectedController() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let controller = FakeLaunchAtLoginController(state: .enabled)

        let store = HealthStore(userDefaults: defaults, launchAtLoginController: controller)

        XCTAssertEqual(store.launchAtLoginState, .enabled)
        XCTAssertNil(store.launchAtLoginErrorMessage)
    }

    func test_setLaunchAtLoginEnabledUpdatesStateAndErrorMessageFromController() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let controller = FakeLaunchAtLoginController(state: .disabled)
        controller.setEnabledHandler = { _, controller in
            controller.state = .requiresApproval
            return LaunchAtLoginActionResult(
                state: .requiresApproval,
                errorMessage: "Approval is still required in System Settings.")
        }

        let store = HealthStore(userDefaults: defaults, launchAtLoginController: controller)
        store.setLaunchAtLoginEnabled(true)

        XCTAssertEqual(controller.requestedEnabledValues, [true])
        XCTAssertEqual(store.launchAtLoginState, .requiresApproval)
        XCTAssertEqual(store.launchAtLoginErrorMessage, "Approval is still required in System Settings.")
    }

    func test_refreshLaunchAtLoginStateClearsPreviousErrorAndReadsControllerState() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let controller = FakeLaunchAtLoginController(state: .disabled)

        let store = HealthStore(userDefaults: defaults, launchAtLoginController: controller)
        store.launchAtLoginErrorMessage = "Previous failure"
        controller.state = .enabled

        store.refreshLaunchAtLoginState()

        XCTAssertEqual(store.launchAtLoginState, .enabled)
        XCTAssertNil(store.launchAtLoginErrorMessage)
    }

    func test_openLaunchAtLoginSystemSettingsDelegatesToController() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let controller = FakeLaunchAtLoginController(state: .disabled)

        let store = HealthStore(userDefaults: defaults, launchAtLoginController: controller)
        store.openLaunchAtLoginSystemSettings()

        XCTAssertEqual(controller.openSystemSettingsCalls, 1)
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

@MainActor
private final class FakeLaunchAtLoginController: LaunchAtLoginControlling {
    var state: LaunchAtLoginState
    var setEnabledHandler: ((Bool, FakeLaunchAtLoginController) -> LaunchAtLoginActionResult)?
    private(set) var requestedEnabledValues: [Bool] = []
    private(set) var openSystemSettingsCalls = 0

    init(state: LaunchAtLoginState) {
        self.state = state
    }

    func currentState() -> LaunchAtLoginState {
        state
    }

    func setEnabled(_ isEnabled: Bool) -> LaunchAtLoginActionResult {
        requestedEnabledValues.append(isEnabled)

        if let setEnabledHandler {
            return setEnabledHandler(isEnabled, self)
        }

        state = isEnabled ? .enabled : .disabled
        return LaunchAtLoginActionResult(state: state, errorMessage: nil)
    }

    func openSystemSettingsLoginItems() {
        openSystemSettingsCalls += 1
    }
}
