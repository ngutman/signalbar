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

    func setSourceMode(_ sourceMode: HealthSourceMode) {
        self.sourceMode = sourceMode
        settingsStore.setSourceMode(sourceMode)
        guard sourceMode == .livePath else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            await refreshHistorySnapshots()
        }
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

    func advanceToNextScenario() {
        let allCases = PreviewScenario.allCases
        guard let currentIndex = allCases.firstIndex(of: previewScenario) else {
            setPreviewScenario(.healthy)
            return
        }
        let nextIndex = allCases.index(after: currentIndex)
        let wrappedIndex = nextIndex == allCases.endIndex ? allCases.startIndex : nextIndex
        setPreviewScenario(allCases[wrappedIndex])
    }
}
