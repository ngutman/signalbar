import Observation
import SwiftUI

@MainActor
struct SettingsView: View {
    static let preferredContentSize = CGSize(width: 640, height: 560)

    @Bindable var store: HealthStore
    @Bindable var selection: SettingsSelection

    var body: some View {
        TabView(selection: $selection.tab) {
            SettingsGeneralPane(store: store)
                .tabItem { Label(SettingsTab.general.title, systemImage: SettingsTab.general.systemImage) }
                .tag(SettingsTab.general)

            SettingsDisplayPane(store: store)
                .tabItem { Label(SettingsTab.display.title, systemImage: SettingsTab.display.systemImage) }
                .tag(SettingsTab.display)

            SettingsTargetsPane(store: store)
                .tabItem { Label(SettingsTab.targets.title, systemImage: SettingsTab.targets.systemImage) }
                .tag(SettingsTab.targets)

            SettingsAboutPane()
                .tabItem { Label(SettingsTab.about.title, systemImage: SettingsTab.about.systemImage) }
                .tag(SettingsTab.about)
        }
        .frame(width: Self.preferredContentSize.width, height: Self.preferredContentSize.height)
    }
}
