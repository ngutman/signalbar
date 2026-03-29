import Foundation
import SignalBarCore

struct WatchedTargetFormState: Equatable {
    enum ValidationError: LocalizedError, Equatable {
        case emptyURL
        case invalidURL
        case unsupportedScheme
        case missingHost

        var errorDescription: String? {
            switch self {
            case .emptyURL:
                "Enter a URL to probe, such as https://github.com."
            case .invalidURL:
                "Enter a valid http:// or https:// URL."
            case .unsupportedScheme:
                "SignalBar currently supports only http:// and https:// watched targets."
            case .missingHost:
                "The watched target URL must include a host name."
            }
        }
    }

    var name: String
    var urlText: String
    var errorMessage: String?

    init(name: String = "", urlText: String = "", errorMessage: String? = nil) {
        self.name = name
        self.urlText = urlText
        self.errorMessage = errorMessage
    }

    init(target: ProbeTarget? = nil) {
        self.init(
            name: target?.name ?? "",
            urlText: target?.url.absoluteString ?? "",
            errorMessage: nil)
    }

    mutating func load(from target: ProbeTarget?) {
        self = WatchedTargetFormState(target: target)
    }

    mutating func clearError() {
        errorMessage = nil
    }

    func makeTarget(existingTarget: ProbeTarget?) throws -> ProbeTarget {
        let trimmedURL = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else {
            throw ValidationError.emptyURL
        }

        guard let url = URL(string: trimmedURL) else {
            throw ValidationError.invalidURL
        }

        guard let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
            throw ValidationError.unsupportedScheme
        }

        guard let host = url.host(), !host.isEmpty else {
            throw ValidationError.missingHost
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return ProbeTarget(
            id: existingTarget?.id ?? UUID(),
            kind: .watched,
            name: trimmedName.isEmpty ? host : trimmedName,
            url: url,
            method: .auto,
            interval: 15,
            timeout: 3.0,
            enabled: true,
            treatHTTP3xxAsSuccess: false)
    }
}
