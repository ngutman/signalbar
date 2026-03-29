import Observation
import SignalBarCore
import SwiftUI

@MainActor
struct SettingsGeneralPane: View {
    @Bindable var store: HealthStore

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { store.launchAtLoginState.isEnabled },
            set: { store.setLaunchAtLoginEnabled($0) })
    }

    private var pauseBinding: Binding<Bool> {
        Binding(
            get: { store.isPaused },
            set: { isPaused in
                if isPaused {
                    store.pause()
                } else {
                    store.resume()
                }
            })
    }

    private var refreshCadenceBinding: Binding<RefreshCadenceProfile> {
        Binding(
            get: { store.refreshCadenceProfile },
            set: { store.setRefreshCadenceProfile($0) })
    }

    private var customRefreshCadenceIntervalBinding: Binding<Int> {
        Binding(
            get: { store.customRefreshCadenceIntervalSeconds },
            set: { store.setCustomRefreshCadenceIntervalSeconds($0) })
    }

    private var customIntervalSubtitle: String {
        let range = RefreshCadenceProfile.customIntervalRange
        return [
            "Enter \(range.lowerBound)–\(range.upperBound) seconds.",
            "Applies to each default control target and the watched target.",
            "SignalBar staggers the default control targets across this interval."
        ].joined(separator: " ")
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSection(
                    title: "Startup",
                    caption: "Control whether SignalBar is available automatically as soon as you sign in.")
                {
                    SettingsToggleRow(
                        title: "Launch at login",
                        subtitle: "Automatically start SignalBar when you log in to your Mac.",
                        isOn: launchAtLoginBinding)
                        .disabled(!store.launchAtLoginState.isAvailable)

                    Text(store.launchAtLoginState.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(
                            store.launchAtLoginState.requiresApproval
                                ? AnyShapeStyle(.orange)
                                : AnyShapeStyle(.tertiary))
                        .fixedSize(horizontal: false, vertical: true)

                    if let errorMessage = store.launchAtLoginErrorMessage, !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if store.launchAtLoginState.requiresApproval {
                        Button("Open Login Items Settings…") {
                            store.openLaunchAtLoginSystemSettings()
                        }
                    }
                }

                Divider()

                SettingsSection(
                    title: "Monitoring",
                    caption: "Choose how often SignalBar runs automatic DNS and internet probes. Manual refresh is always available.")
                {
                    SettingsPickerRow(
                        title: "Refresh cadence",
                        subtitle: refreshCadenceBinding.wrappedValue.detailText(
                            customIntervalSeconds: store.customRefreshCadenceIntervalSeconds))
                    {
                        Picker("Refresh cadence", selection: refreshCadenceBinding) {
                            ForEach(RefreshCadenceProfile.allCases, id: \.self) { profile in
                                Text(profile.displayName).tag(profile)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(maxWidth: 200)
                    }

                    if store.refreshCadenceProfile == .custom {
                        SettingsPickerRow(
                            title: "Custom interval",
                            subtitle: customIntervalSubtitle)
                        {
                            HStack(spacing: 8) {
                                TextField("Seconds", value: customRefreshCadenceIntervalBinding, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 72)

                                Text("seconds")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                Stepper(
                                    "Custom interval",
                                    value: customRefreshCadenceIntervalBinding,
                                    in: RefreshCadenceProfile.customIntervalRange,
                                    step: 1)
                                    .labelsHidden()
                            }
                        }
                    }

                    SettingsToggleRow(
                        title: "Pause probing",
                        subtitle: "Stops automatic DNS and internet sweeps. Manual refresh still works while paused.",
                        isOn: pauseBinding)
                }

                Divider()

                SettingsSection(
                    title: "History",
                    caption: "SignalBar remembers your most recent history metric and time range from the menu.")
                {
                    Text(
                        "History selectors stay inline in the menu because they are part of reading the current diagnosis, not global app preferences.")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()

                SettingsSection(
                    title: "Coming later",
                    caption: "These settings are planned, but they should land only once the underlying behavior is implemented and tested.")
                {
                    Text("Notifications · Low Power Mode backoff behavior")
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
