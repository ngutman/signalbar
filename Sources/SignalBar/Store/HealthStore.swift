import Foundation
import Observation
import SignalBarCore

@MainActor
@Observable
final class HealthStore {
    var sourceMode: HealthSourceMode
    var previewScenario: PreviewScenario
    var watchedTarget: ProbeTarget?
    var snapshot: HealthSnapshot?
    var liveHistorySnapshot: HistorySnapshot?
    var toolbarHistorySnapshot: HistorySnapshot?
    var timelineWindow: HistoryWindow
    var historyMetric: HistoryMetric
    var previewUpdatedAt: Date
    var currentDate: Date
    var isPaused: Bool
    var displayMode: MenuBarDisplayMode
    var colorMode: MenuBarColorMode

    @ObservationIgnored let settingsStore: SettingsStore
    @ObservationIgnored let healthEngine: HealthEngine
    @ObservationIgnored let freshnessPolicy = SnapshotFreshnessPolicy()
    @ObservationIgnored var engineTask: Task<Void, Never>?
    @ObservationIgnored var clockTask: Task<Void, Never>?

    init(
        sourceMode: HealthSourceMode? = nil,
        previewScenario: PreviewScenario = .healthy,
        updatedAt: Date = .now,
        isPaused: Bool? = nil,
        healthEngine: HealthEngine = HealthEngine(),
        userDefaults: UserDefaults = .standard,
        settingsStore: SettingsStore? = nil)
    {
        let resolvedSettingsStore = settingsStore ?? SettingsStore(userDefaults: userDefaults)
        self.settingsStore = resolvedSettingsStore
        self.healthEngine = healthEngine
        self.sourceMode = sourceMode ?? .livePath
        self.previewScenario = previewScenario
        watchedTarget = resolvedSettingsStore.watchedTarget
        snapshot = nil
        liveHistorySnapshot = nil
        toolbarHistorySnapshot = nil
        timelineWindow = resolvedSettingsStore.timelineWindow
        historyMetric = resolvedSettingsStore.historyMetric
        previewUpdatedAt = updatedAt
        currentDate = updatedAt
        self.isPaused = isPaused ?? resolvedSettingsStore.isPaused
        displayMode = resolvedSettingsStore.displayMode
        colorMode = resolvedSettingsStore.colorMode
    }

    deinit {
        self.engineTask?.cancel()
        self.clockTask?.cancel()
    }

    func startClock() {
        guard clockTask == nil else { return }
        clockTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { break }
                currentDate = .now
            }
        }
    }

    func refreshHistorySnapshots() async {
        let toolbarHistorySnapshot = await healthEngine.historySnapshot(for: .oneMinute)
        self.toolbarHistorySnapshot = toolbarHistorySnapshot
        if timelineWindow == .oneMinute {
            liveHistorySnapshot = toolbarHistorySnapshot
        } else {
            liveHistorySnapshot = await healthEngine.historySnapshot(for: timelineWindow)
        }
    }
}
