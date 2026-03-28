import Foundation

enum LayerStatusEvaluator {
    static func dnsLayerStatus(successRate: Double, medianLatencyMs: Double?) -> LayerStatus {
        guard successRate > 0 else { return .failed }
        if successRate < 0.75 { return .failed }
        if let medianLatencyMs, medianLatencyMs >= 150 { return .degraded }
        if successRate < 0.95 { return .degraded }
        return .healthy
    }

    static func internetLayerStatus(successRate: Double, medianLatencyMs: Double?) -> LayerStatus {
        guard successRate > 0 else { return .failed }
        if successRate < 0.80 { return .failed }
        if let medianLatencyMs, medianLatencyMs >= 300 { return .degraded }
        if successRate < 0.95 { return .degraded }
        return .healthy
    }

    static func qualityLayerStatus(
        successRate: Double,
        medianLatencyMs: Double?,
        jitterMs: Double?,
        hasHTTPSamples: Bool) -> LayerStatus
    {
        guard hasHTTPSamples else { return .pending }
        if successRate <= 0 { return .unavailable }
        if let medianLatencyMs, medianLatencyMs >= 500 { return .failed }
        if let jitterMs, jitterMs >= 120 { return .failed }
        if let medianLatencyMs, medianLatencyMs >= 200 { return .degraded }
        if let jitterMs, jitterMs >= 60 { return .degraded }
        if successRate < 0.95 { return .degraded }
        return .healthy
    }
}
