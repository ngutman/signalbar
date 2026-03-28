import Foundation

public enum DNSFailure: String, Sendable, Codable {
    case timeout
    case noRecords
    case resolverFailure
    case cancelled
    case unknown
}

public enum HTTPProbeFailure: String, Sendable, Codable {
    case dns
    case connect
    case tls
    case timeout
    case badStatus
    case cancelled
    case unknown
}

public struct DNSProbeResult: Sendable, Codable, Equatable {
    public let targetID: UUID
    public let startedAt: Date
    public let durationMs: Double?
    public let success: Bool
    public let resolvedAddresses: Int
    public let failure: DNSFailure?

    public init(
        targetID: UUID,
        startedAt: Date,
        durationMs: Double?,
        success: Bool,
        resolvedAddresses: Int,
        failure: DNSFailure?)
    {
        self.targetID = targetID
        self.startedAt = startedAt
        self.durationMs = durationMs
        self.success = success
        self.resolvedAddresses = resolvedAddresses
        self.failure = failure
    }
}

public struct HTTPProbeResult: Sendable, Codable, Equatable {
    public let targetID: UUID
    public let startedAt: Date
    public let dnsMs: Double?
    public let connectMs: Double?
    public let tlsMs: Double?
    public let firstByteMs: Double?
    public let totalMs: Double?
    public let statusCode: Int?
    public let success: Bool
    public let reusedConnection: Bool
    public let failure: HTTPProbeFailure?

    public init(
        targetID: UUID,
        startedAt: Date,
        dnsMs: Double?,
        connectMs: Double?,
        tlsMs: Double?,
        firstByteMs: Double?,
        totalMs: Double?,
        statusCode: Int?,
        success: Bool,
        reusedConnection: Bool,
        failure: HTTPProbeFailure?)
    {
        self.targetID = targetID
        self.startedAt = startedAt
        self.dnsMs = dnsMs
        self.connectMs = connectMs
        self.tlsMs = tlsMs
        self.firstByteMs = firstByteMs
        self.totalMs = totalMs
        self.statusCode = statusCode
        self.success = success
        self.reusedConnection = reusedConnection
        self.failure = failure
    }
}

public struct TargetProbeSample: Sendable, Codable, Equatable {
    public let target: ProbeTarget
    public let dns: DNSProbeResult?
    public let http: HTTPProbeResult?

    public init(target: ProbeTarget, dns: DNSProbeResult?, http: HTTPProbeResult?) {
        self.target = target
        self.dns = dns
        self.http = http
    }
}
