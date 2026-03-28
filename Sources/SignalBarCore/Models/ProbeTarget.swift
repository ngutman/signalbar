import Foundation

public enum ProbeTargetKind: String, Sendable, Codable {
    case control
    case custom
    case watched
}

public enum ProbeMethod: String, Sendable, Codable {
    case auto
    case head
    case get
}

public struct ProbeTarget: Sendable, Codable, Identifiable, Hashable {
    public let id: UUID
    public let kind: ProbeTargetKind
    public let name: String
    public let url: URL
    public let host: String
    public let method: ProbeMethod
    public let interval: TimeInterval
    public let timeout: TimeInterval
    public let enabled: Bool
    public let treatHTTP3xxAsSuccess: Bool
    public let expectedStatusCodes: [Int]?

    public init(
        id: UUID = UUID(),
        kind: ProbeTargetKind,
        name: String,
        url: URL,
        method: ProbeMethod,
        interval: TimeInterval,
        timeout: TimeInterval,
        enabled: Bool = true,
        treatHTTP3xxAsSuccess: Bool = false,
        expectedStatusCodes: [Int]? = nil)
    {
        self.id = id
        self.kind = kind
        self.name = name
        self.url = url
        host = url.host() ?? url.absoluteString
        self.method = method
        self.interval = interval
        self.timeout = timeout
        self.enabled = enabled
        self.treatHTTP3xxAsSuccess = treatHTTP3xxAsSuccess
        self.expectedStatusCodes = expectedStatusCodes
    }
}

public extension ProbeTarget {
    static let defaultControlTargets: [ProbeTarget] = [
        .init(
            kind: .control,
            name: "Apple",
            url: URL(string: "https://www.apple.com/library/test/success.html")!,
            method: .head,
            interval: 15,
            timeout: 2.5,
            expectedStatusCodes: [200]),
        .init(
            kind: .control,
            name: "Cloudflare",
            url: URL(string: "https://cp.cloudflare.com/generate_204")!,
            method: .head,
            interval: 15,
            timeout: 2.5,
            expectedStatusCodes: [204]),
        .init(
            kind: .control,
            name: "Google",
            url: URL(string: "https://www.google.com/generate_204")!,
            method: .head,
            interval: 15,
            timeout: 2.5,
            expectedStatusCodes: [204])
    ]
}
