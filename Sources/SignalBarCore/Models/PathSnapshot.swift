import Foundation

public enum PathStatus: String, Sendable, Codable {
    case satisfied
    case unsatisfied
    case requiresConnection
}

public enum InterfaceKind: String, Sendable, Codable {
    case wifi
    case ethernet
    case cellular
    case other
}

public struct PathSnapshot: Sendable, Codable, Equatable {
    public let observedAt: Date
    public let status: PathStatus
    public let interface: InterfaceKind?
    public let isConstrained: Bool
    public let isExpensive: Bool
    public let supportsDNS: Bool
    public let supportsIPv4: Bool
    public let supportsIPv6: Bool

    public init(
        observedAt: Date,
        status: PathStatus,
        interface: InterfaceKind?,
        isConstrained: Bool,
        isExpensive: Bool,
        supportsDNS: Bool,
        supportsIPv4: Bool,
        supportsIPv6: Bool)
    {
        self.observedAt = observedAt
        self.status = status
        self.interface = interface
        self.isConstrained = isConstrained
        self.isExpensive = isExpensive
        self.supportsDNS = supportsDNS
        self.supportsIPv4 = supportsIPv4
        self.supportsIPv6 = supportsIPv6
    }
}
