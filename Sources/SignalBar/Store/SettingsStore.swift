import Foundation
import SignalBarCore

@MainActor
final class SettingsStore {
    private static let displayModeDefaultsKey = "menuBarDisplayMode"
    private static let colorModeDefaultsKey = "menuBarColorMode"
    private static let timelineWindowDefaultsKey = "timelineWindow"
    private static let historyMetricDefaultsKey = "historyMetric"
    private static let watchedTargetDefaultsKey = "watchedTarget"
    private static let pausedDefaultsKey = "isPaused"
    private static let refreshCadenceProfileDefaultsKey = "refreshCadenceProfile"
    private static let customRefreshCadenceIntervalSecondsDefaultsKey = "customRefreshCadenceIntervalSeconds"
    private static let lowPowerModeBackoffEnabledDefaultsKey = "lowPowerModeBackoffEnabled"

    private let userDefaults: UserDefaults

    private(set) var watchedTarget: ProbeTarget?
    private(set) var timelineWindow: HistoryWindow
    private(set) var historyMetric: HistoryMetric
    private(set) var displayMode: MenuBarDisplayMode
    private(set) var colorMode: MenuBarColorMode
    private(set) var isPaused: Bool
    private(set) var refreshCadenceProfile: RefreshCadenceProfile
    private(set) var customRefreshCadenceIntervalSeconds: Int
    private(set) var lowPowerModeBackoffEnabled: Bool

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        watchedTarget = Self.loadWatchedTarget(from: userDefaults)
        timelineWindow = Self.loadTimelineWindow(from: userDefaults)
        historyMetric = Self.loadHistoryMetric(from: userDefaults)
        displayMode = Self.loadDisplayMode(from: userDefaults)
        colorMode = Self.loadColorMode(from: userDefaults)
        isPaused = Self.loadIsPaused(from: userDefaults)
        refreshCadenceProfile = Self.loadRefreshCadenceProfile(from: userDefaults)
        customRefreshCadenceIntervalSeconds = Self.loadCustomRefreshCadenceIntervalSeconds(from: userDefaults)
        lowPowerModeBackoffEnabled = Self.loadLowPowerModeBackoffEnabled(from: userDefaults)
    }

    func setWatchedTarget(_ watchedTarget: ProbeTarget?) {
        self.watchedTarget = watchedTarget
        Self.storeWatchedTarget(watchedTarget, in: userDefaults)
    }

    func setTimelineWindow(_ timelineWindow: HistoryWindow) {
        self.timelineWindow = timelineWindow
        userDefaults.set(timelineWindow.rawValue, forKey: Self.timelineWindowDefaultsKey)
    }

    func setHistoryMetric(_ historyMetric: HistoryMetric) {
        self.historyMetric = historyMetric
        userDefaults.set(historyMetric.rawValue, forKey: Self.historyMetricDefaultsKey)
    }

    func setDisplayMode(_ displayMode: MenuBarDisplayMode) {
        self.displayMode = displayMode
        userDefaults.set(displayMode.rawValue, forKey: Self.displayModeDefaultsKey)
    }

    func setColorMode(_ colorMode: MenuBarColorMode) {
        self.colorMode = colorMode
        userDefaults.set(colorMode.rawValue, forKey: Self.colorModeDefaultsKey)
    }

    func setPaused(_ isPaused: Bool) {
        self.isPaused = isPaused
        userDefaults.set(isPaused, forKey: Self.pausedDefaultsKey)
    }

    func setRefreshCadenceProfile(_ refreshCadenceProfile: RefreshCadenceProfile) {
        self.refreshCadenceProfile = refreshCadenceProfile
        userDefaults.set(refreshCadenceProfile.rawValue, forKey: Self.refreshCadenceProfileDefaultsKey)
    }

    func setCustomRefreshCadenceIntervalSeconds(_ customRefreshCadenceIntervalSeconds: Int) {
        let clampedIntervalSeconds = ProbeCadenceConfiguration.clampCustomIntervalSeconds(customRefreshCadenceIntervalSeconds)
        self.customRefreshCadenceIntervalSeconds = clampedIntervalSeconds
        userDefaults.set(clampedIntervalSeconds, forKey: Self.customRefreshCadenceIntervalSecondsDefaultsKey)
    }

    func setLowPowerModeBackoffEnabled(_ lowPowerModeBackoffEnabled: Bool) {
        self.lowPowerModeBackoffEnabled = lowPowerModeBackoffEnabled
        userDefaults.set(lowPowerModeBackoffEnabled, forKey: Self.lowPowerModeBackoffEnabledDefaultsKey)
    }

    private static func loadDisplayMode(from userDefaults: UserDefaults) -> MenuBarDisplayMode {
        guard let rawValue = userDefaults.string(forKey: displayModeDefaultsKey),
              let displayMode = MenuBarDisplayMode(rawValue: rawValue)
        else {
            return .defaultValue
        }
        return displayMode
    }

    private static func loadColorMode(from userDefaults: UserDefaults) -> MenuBarColorMode {
        guard let rawValue = userDefaults.string(forKey: colorModeDefaultsKey),
              let colorMode = MenuBarColorMode(rawValue: rawValue)
        else {
            return .defaultValue
        }
        return colorMode
    }

    private static func loadTimelineWindow(from userDefaults: UserDefaults) -> HistoryWindow {
        guard let rawValue = userDefaults.string(forKey: timelineWindowDefaultsKey),
              let timelineWindow = HistoryWindow(rawValue: rawValue)
        else {
            return .defaultValue
        }
        return timelineWindow
    }

    private static func loadHistoryMetric(from userDefaults: UserDefaults) -> HistoryMetric {
        guard let rawValue = userDefaults.string(forKey: historyMetricDefaultsKey),
              let historyMetric = HistoryMetric(rawValue: rawValue)
        else {
            return .defaultValue
        }
        return historyMetric
    }

    private static func loadWatchedTarget(from userDefaults: UserDefaults) -> ProbeTarget? {
        guard let data = userDefaults.data(forKey: watchedTargetDefaultsKey) else { return nil }
        return try? JSONDecoder().decode(ProbeTarget.self, from: data)
    }

    private static func loadIsPaused(from userDefaults: UserDefaults) -> Bool {
        userDefaults.bool(forKey: pausedDefaultsKey)
    }

    private static func loadRefreshCadenceProfile(from userDefaults: UserDefaults) -> RefreshCadenceProfile {
        guard let rawValue = userDefaults.string(forKey: refreshCadenceProfileDefaultsKey),
              let refreshCadenceProfile = RefreshCadenceProfile(rawValue: rawValue)
        else {
            return .defaultValue
        }
        return refreshCadenceProfile
    }

    private static func loadCustomRefreshCadenceIntervalSeconds(from userDefaults: UserDefaults) -> Int {
        let storedValue = userDefaults.integer(forKey: customRefreshCadenceIntervalSecondsDefaultsKey)
        if storedValue == 0 {
            return RefreshCadenceProfile.defaultCustomIntervalSeconds
        }
        return ProbeCadenceConfiguration.clampCustomIntervalSeconds(storedValue)
    }

    private static func loadLowPowerModeBackoffEnabled(from userDefaults: UserDefaults) -> Bool {
        if userDefaults.object(forKey: lowPowerModeBackoffEnabledDefaultsKey) == nil {
            return true
        }
        return userDefaults.bool(forKey: lowPowerModeBackoffEnabledDefaultsKey)
    }

    private static func storeWatchedTarget(_ watchedTarget: ProbeTarget?, in userDefaults: UserDefaults) {
        if let watchedTarget, let data = try? JSONEncoder().encode(watchedTarget) {
            userDefaults.set(data, forKey: watchedTargetDefaultsKey)
        } else {
            userDefaults.removeObject(forKey: Self.watchedTargetDefaultsKey)
        }
    }
}
