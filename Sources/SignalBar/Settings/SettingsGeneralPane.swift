import Observation
import SwiftUI

@MainActor
struct SettingsGeneralPane: View {
    @Bindable var store: HealthStore

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

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSection(
                    title: "Monitoring",
                    caption: "Keep quick actions in the menu, and use settings for persistent app behavior.")
                {
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
                    Text("Launch at login · notifications · refresh cadence / Low Power Mode behavior")
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
