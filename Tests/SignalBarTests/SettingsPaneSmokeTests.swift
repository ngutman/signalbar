import AppKit
@testable import SignalBar
import SignalBarCore
import SwiftUI
import XCTest

@MainActor
final class SettingsPaneSmokeTests: XCTestCase {
    func test_buildsSettingsPanesWithDefaultState() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = HealthStore(userDefaults: defaults)
        let selection = SettingsSelection()

        _ = SettingsGeneralPane(store: store).body
        _ = SettingsDisplayPane(store: store).body
        _ = SettingsTargetsPane(store: store).body
        _ = SettingsAboutPane().body
        _ = SettingsView(store: store, selection: selection).body
    }

    func test_buildsSettingsPanesWithConfiguredWatchedTargetAndPausedState() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = HealthStore(userDefaults: defaults)
        store.pause()
        store.setDisplayMode(.semanticBars)
        store.setColorMode(.mutedAccent)
        store.setWatchedTarget(
            ProbeTarget(
                kind: .watched,
                name: "GitHub",
                url: URL(string: "https://github.com")!,
                method: .auto,
                interval: 15,
                timeout: 3.0))

        _ = SettingsGeneralPane(store: store).body
        _ = SettingsDisplayPane(store: store).body
        _ = SettingsTargetsPane(store: store).body
    }
}
