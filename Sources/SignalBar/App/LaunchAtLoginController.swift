import Foundation
import ServiceManagement

@MainActor
protocol LaunchAtLoginControlling {
    func currentState() -> LaunchAtLoginState
    func setEnabled(_ isEnabled: Bool) -> LaunchAtLoginActionResult
    func openSystemSettingsLoginItems()
}

struct LaunchAtLoginActionResult: Equatable {
    let state: LaunchAtLoginState
    let errorMessage: String?
}

enum LaunchAtLoginState: Equatable, Sendable {
    case disabled
    case enabled
    case requiresApproval
    case unavailable(String)

    var isEnabled: Bool {
        switch self {
        case .enabled, .requiresApproval:
            true
        case .disabled, .unavailable:
            false
        }
    }

    var isAvailable: Bool {
        switch self {
        case .unavailable:
            false
        case .disabled, .enabled, .requiresApproval:
            true
        }
    }

    var requiresApproval: Bool {
        switch self {
        case .requiresApproval:
            true
        case .disabled, .enabled, .unavailable:
            false
        }
    }

    var statusMessage: String {
        switch self {
        case .disabled:
            "SignalBar will not start automatically when you log in."
        case .enabled:
            "SignalBar will start automatically when you log in."
        case .requiresApproval:
            "SignalBar was added as a login item, but macOS still requires approval in System Settings."
        case let .unavailable(message):
            message
        }
    }
}

@MainActor
final class LaunchAtLoginController: LaunchAtLoginControlling {
    private static let developmentUnavailableMessage =
        "Launch at login is only available from the packaged SignalBar.app bundle, not the development binary started by ./run-menubar.sh."
    private static let bundleUnavailableMessage =
        "SignalBar couldn’t find a login-item registration for the current app bundle. Try the packaged SignalBar.app build and reopen Settings."

    private let bundle: Bundle
    private let appService: SMAppService

    init(bundle: Bundle = .main, appService: SMAppService = .mainApp) {
        self.bundle = bundle
        self.appService = appService
    }

    func currentState() -> LaunchAtLoginState {
        guard isRunningFromAppBundle else {
            return .unavailable(Self.developmentUnavailableMessage)
        }

        return Self.mapStatus(appService.status)
    }

    func setEnabled(_ isEnabled: Bool) -> LaunchAtLoginActionResult {
        guard isRunningFromAppBundle else {
            return LaunchAtLoginActionResult(
                state: .unavailable(Self.developmentUnavailableMessage),
                errorMessage: nil)
        }

        do {
            switch (isEnabled, appService.status) {
            case (true, .enabled), (true, .requiresApproval):
                break
            case (true, _):
                try appService.register()
            case (false, .notRegistered):
                break
            case (false, _):
                try appService.unregister()
            }
        } catch {
            return LaunchAtLoginActionResult(
                state: currentState(),
                errorMessage: error.localizedDescription)
        }

        return LaunchAtLoginActionResult(state: currentState(), errorMessage: nil)
    }

    func openSystemSettingsLoginItems() {
        SMAppService.openSystemSettingsLoginItems()
    }

    private var isRunningFromAppBundle: Bool {
        bundle.bundleURL.pathExtension == "app"
    }

    private static func mapStatus(_ status: SMAppService.Status) -> LaunchAtLoginState {
        switch status {
        case .notRegistered:
            .disabled
        case .enabled:
            .enabled
        case .requiresApproval:
            .requiresApproval
        case .notFound:
            .unavailable(bundleUnavailableMessage)
        @unknown default:
            .unavailable(bundleUnavailableMessage)
        }
    }
}
