import AppKit
import SignalBarCore

@MainActor
extension StatusItemController {
    @objc func selectDisplayMode(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let displayMode = MenuBarDisplayMode(rawValue: rawValue)
        else {
            return
        }
        store.setDisplayMode(displayMode)
    }

    @objc func selectColorMode(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let colorMode = MenuBarColorMode(rawValue: rawValue)
        else {
            return
        }
        store.setColorMode(colorMode)
    }

    @objc func configureWatchedTarget() {
        let existingTarget = store.watchedTarget
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = existingTarget == nil ? "Add watched target" : "Edit watched target"
        alert.informativeText = "SignalBar will probe this target separately and flag service-specific issues when the core internet path still looks healthy."
        alert.addButton(withTitle: existingTarget == nil ? "Add" : "Save")
        alert.addButton(withTitle: "Cancel")

        let nameField = NSTextField(string: existingTarget?.name ?? "")
        let urlField = NSTextField(string: existingTarget?.url.absoluteString ?? "https://github.com")
        nameField.placeholderString = "Name (optional)"
        urlField.placeholderString = "https://example.com/health"
        nameField.frame.size.width = 320
        urlField.frame.size.width = 320

        let stackView = NSStackView(views: [
            NSTextField(labelWithString: "Name"),
            nameField,
            NSTextField(labelWithString: "URL"),
            urlField
        ])
        stackView.orientation = .vertical
        stackView.spacing = 6
        alert.accessoryView = stackView

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let trimmedURL = urlField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmedURL),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              let host = url.host(), !host.isEmpty
        else {
            presentValidationError(message: "Please enter a valid http:// or https:// URL.")
            return
        }

        let trimmedName = nameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let target = ProbeTarget(
            id: existingTarget?.id ?? UUID(),
            kind: .watched,
            name: trimmedName.isEmpty ? host : trimmedName,
            url: url,
            method: .auto,
            interval: 15,
            timeout: 3.0,
            enabled: true,
            treatHTTP3xxAsSuccess: false)
        store.setWatchedTarget(target)
    }

    @objc func removeWatchedTarget() {
        store.setWatchedTarget(nil)
    }

    private func presentValidationError(message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Invalid watched target"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc func refreshNow() {
        store.refreshNow()
    }

    @objc func togglePauseProbing() {
        if store.isPaused {
            store.resume()
        } else {
            store.pause()
        }
    }

    @objc func copyDiagnosticSummary() {
        let summary = DiagnosticSummaryBuilder.summary(for: store.presentation)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(summary, forType: .string)
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }
}
