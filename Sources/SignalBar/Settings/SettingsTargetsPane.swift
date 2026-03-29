import Observation
import SignalBarCore
import SwiftUI

@MainActor
struct SettingsTargetsPane: View {
    @Bindable var store: HealthStore
    @State private var formState: WatchedTargetFormState

    init(store: HealthStore) {
        self.store = store
        _formState = State(initialValue: WatchedTargetFormState(target: store.watchedTarget))
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSection(
                    title: "Watched target",
                    caption: "Probe one service separately so SignalBar can tell you when the core internet path is healthy but that specific endpoint is not.")
                {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Label")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Name (optional)", text: nameBinding)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("URL")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("https://example.com/health", text: urlBinding)
                            .textFieldStyle(.roundedBorder)
                    }

                    if let errorMessage = formState.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 10) {
                        Button(store.watchedTarget == nil ? "Save watched target" : "Update watched target") {
                            saveWatchedTarget()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Reset") {
                            formState.load(from: store.watchedTarget)
                        }
                        .buttonStyle(.bordered)

                        Button("Remove watched target") {
                            removeWatchedTarget()
                        }
                        .buttonStyle(.bordered)
                        .disabled(store.watchedTarget == nil)
                    }
                }

                Divider()

                SettingsSection(title: "Current behavior") {
                    Text(currentBehaviorText)
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .onChange(of: store.watchedTarget) { _, watchedTarget in
                formState.load(from: watchedTarget)
            }
        }
    }

    private var nameBinding: Binding<String> {
        Binding(
            get: { formState.name },
            set: { newValue in
                formState.name = newValue
                formState.clearError()
            })
    }

    private var urlBinding: Binding<String> {
        Binding(
            get: { formState.urlText },
            set: { newValue in
                formState.urlText = newValue
                formState.clearError()
            })
    }

    private var currentBehaviorText: String {
        if let watchedTarget = store.watchedTarget {
            return """
            Current watched target: \(watchedTarget.name) · \(watchedTarget.url.absoluteString)

            A watched-target failure should not make the core internet bars look broken when the control targets still look healthy.
            """
        }
        return "No watched target is configured. Add one to get service-specific diagnosis without changing the meaning of the four core layers."
    }

    private func saveWatchedTarget() {
        do {
            let target = try formState.makeTarget(existingTarget: store.watchedTarget)
            store.setWatchedTarget(target)
            formState.load(from: target)
        } catch let error as WatchedTargetFormState.ValidationError {
            formState.errorMessage = error.localizedDescription
        } catch {
            formState.errorMessage = "SignalBar could not save that watched target."
        }
    }

    private func removeWatchedTarget() {
        store.setWatchedTarget(nil)
        formState.load(from: nil)
    }
}
