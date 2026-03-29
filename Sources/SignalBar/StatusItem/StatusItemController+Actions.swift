import AppKit

@MainActor
extension StatusItemController {
    @objc func openSettings() {
        openSettingsHandler()
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
