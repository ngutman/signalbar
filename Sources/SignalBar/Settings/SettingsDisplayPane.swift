import Observation
import SwiftUI

@MainActor
struct SettingsDisplayPane: View {
    @Bindable var store: HealthStore

    private var displayModeBinding: Binding<MenuBarDisplayMode> {
        Binding(
            get: { store.displayMode },
            set: { store.setDisplayMode($0) })
    }

    private var colorModeBinding: Binding<MenuBarColorMode> {
        Binding(
            get: { store.colorMode },
            set: { store.setColorMode($0) })
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSection(
                    title: "Toolbar appearance",
                    caption: "Choose how SignalBar renders the four health layers in the menu bar.")
                {
                    SettingsPickerRow(
                        title: "Toolbar icon style",
                        subtitle: displayModeBinding.wrappedValue.detailText)
                    {
                        Picker("Toolbar icon style", selection: displayModeBinding) {
                            ForEach(MenuBarDisplayMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(maxWidth: 200)
                    }

                    SettingsPickerRow(
                        title: "Color style",
                        subtitle: colorModeBinding.wrappedValue.detailText)
                    {
                        Picker("Color style", selection: colorModeBinding) {
                            ForEach(MenuBarColorMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(maxWidth: 200)
                    }
                }

                Divider()

                SettingsSection(
                    title: "History controls",
                    caption: "SignalBar keeps the history metric and range selectors in the menu so they stay close to the diagnosis card.")
                {
                    Text("The last-used history metric and time range are still remembered between launches.")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
}
