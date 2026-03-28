import Foundation

public enum HealthLayer: String, Sendable, Codable, CaseIterable {
    case link
    case dns
    case internet
    case quality

    public var displayName: String {
        switch self {
        case .link:
            "Link"
        case .dns:
            "DNS"
        case .internet:
            "Internet"
        case .quality:
            "Quality"
        }
    }
}

public enum LayerStatus: String, Sendable, Codable, CaseIterable {
    case healthy
    case degraded
    case failed
    case pending
    case unavailable

    public var displayName: String {
        switch self {
        case .healthy:
            "Healthy"
        case .degraded:
            "Degraded"
        case .failed:
            "Failed"
        case .pending:
            "Pending"
        case .unavailable:
            "Unavailable"
        }
    }
}

public extension InterfaceKind {
    var displayName: String {
        switch self {
        case .wifi:
            "Wi-Fi"
        case .ethernet:
            "Ethernet"
        case .cellular:
            "Cellular"
        case .other:
            "Other"
        }
    }
}
