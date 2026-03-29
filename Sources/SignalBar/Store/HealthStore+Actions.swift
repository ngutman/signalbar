import SignalBarCore

@MainActor
extension HealthStore {
    func start() {
        guard engineTask == nil else { return }
        startClock()
        engineTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await healthEngine.updateWatchedTarget(watchedTarget)
            if isPaused {
                await healthEngine.pause()
            } else {
                await healthEngine.resume()
            }
            let stream = await healthEngine.start()
            await refreshHistorySnapshots()
            for await snapshot in stream {
                guard !Task.isCancelled else { break }
                self.snapshot = snapshot
                currentDate = .now
                await refreshHistorySnapshots()
            }
        }
    }

    func refreshNow() {
        currentDate = .now
        Task {
            await self.healthEngine.refreshNow()
        }
    }

    func setTimelineWindow(_ timelineWindow: HistoryWindow) {
        self.timelineWindow = timelineWindow
        settingsStore.setTimelineWindow(timelineWindow)
        guard sourceMode == .livePath else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            liveHistorySnapshot = await healthEngine.historySnapshot(for: timelineWindow)
        }
    }

    func setHistoryMetric(_ historyMetric: HistoryMetric) {
        self.historyMetric = historyMetric
        settingsStore.setHistoryMetric(historyMetric)
    }

    func setPreviewScenario(_ scenario: PreviewScenario) {
        previewScenario = scenario
        previewUpdatedAt = .now
        currentDate = .now
    }

    func setWatchedTarget(_ watchedTarget: ProbeTarget?) {
        self.watchedTarget = watchedTarget
        settingsStore.setWatchedTarget(watchedTarget)
        Task {
            await self.healthEngine.updateWatchedTarget(watchedTarget)
        }
    }

    func refreshLaunchAtLoginState() {
        launchAtLoginState = launchAtLoginController.currentState()
        launchAtLoginErrorMessage = nil
    }

    func setLaunchAtLoginEnabled(_ isEnabled: Bool) {
        let result = launchAtLoginController.setEnabled(isEnabled)
        launchAtLoginState = result.state
        launchAtLoginErrorMessage = result.errorMessage
    }

    func openLaunchAtLoginSystemSettings() {
        launchAtLoginController.openSystemSettingsLoginItems()
    }

    func pause() {
        guard !isPaused else { return }
        isPaused = true
        currentDate = .now
        settingsStore.setPaused(true)
        Task {
            await self.healthEngine.pause()
        }
    }

    func resume() {
        guard isPaused else { return }
        isPaused = false
        currentDate = .now
        settingsStore.setPaused(false)
        Task {
            await self.healthEngine.resume()
            await self.healthEngine.refreshNow()
        }
    }

    func setDisplayMode(_ displayMode: MenuBarDisplayMode) {
        self.displayMode = displayMode
        settingsStore.setDisplayMode(displayMode)
    }

    func setColorMode(_ colorMode: MenuBarColorMode) {
        self.colorMode = colorMode
        settingsStore.setColorMode(colorMode)
    }
}
