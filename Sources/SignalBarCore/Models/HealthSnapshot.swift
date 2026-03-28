import Foundation

public struct LayerHealthSnapshot: Sendable, Codable, Equatable {
    public let layer: HealthLayer
    public let status: LayerStatus
    public let score: Double
    public let title: String
    public let explanation: String
    public let primaryMetricText: String?

    public init(
        layer: HealthLayer,
        status: LayerStatus,
        score: Double,
        title: String,
        explanation: String,
        primaryMetricText: String?)
    {
        self.layer = layer
        self.status = status
        self.score = score
        self.title = title
        self.explanation = explanation
        self.primaryMetricText = primaryMetricText
    }
}

public struct TargetHealth: Sendable, Codable, Equatable, Identifiable {
    public let id: UUID
    public let target: ProbeTarget
    public let medianLatencyMs: Double?
    public let jitterMs: Double?
    public let successRate: Double
    public let lastFailureText: String?
    public let latestHTTP: HTTPProbeResult?
    public let latestDNS: DNSProbeResult?

    public init(
        id: UUID,
        target: ProbeTarget,
        medianLatencyMs: Double?,
        jitterMs: Double?,
        successRate: Double,
        lastFailureText: String?,
        latestHTTP: HTTPProbeResult?,
        latestDNS: DNSProbeResult?)
    {
        self.id = id
        self.target = target
        self.medianLatencyMs = medianLatencyMs
        self.jitterMs = jitterMs
        self.successRate = successRate
        self.lastFailureText = lastFailureText
        self.latestHTTP = latestHTTP
        self.latestDNS = latestDNS
    }
}

public struct HealthSnapshot: Sendable, Codable, Equatable {
    public let generatedAt: Date
    public let path: PathSnapshot?
    public let layers: [LayerHealthSnapshot]
    public let controlTargets: [TargetHealth]
    public let watchedTarget: TargetHealth?
    public let diagnosis: Diagnosis
    public let isStale: Bool
    public let overallScore: Double
    public let medianLatencyMs: Double?
    public let jitterMs: Double?
    public let reliability: Double

    public init(
        generatedAt: Date,
        path: PathSnapshot?,
        layers: [LayerHealthSnapshot],
        controlTargets: [TargetHealth],
        watchedTarget: TargetHealth?,
        diagnosis: Diagnosis,
        isStale: Bool,
        overallScore: Double,
        medianLatencyMs: Double?,
        jitterMs: Double?,
        reliability: Double)
    {
        self.generatedAt = generatedAt
        self.path = path
        self.layers = layers
        self.controlTargets = controlTargets
        self.watchedTarget = watchedTarget
        self.diagnosis = diagnosis
        self.isStale = isStale
        self.overallScore = overallScore
        self.medianLatencyMs = medianLatencyMs
        self.jitterMs = jitterMs
        self.reliability = reliability
    }
}
