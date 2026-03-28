import Foundation

enum LayerSnapshotFactory {
    static func dnsLayer(status: LayerStatus, successRate: Double, medianLatencyMs: Double?) -> LayerHealthSnapshot {
        let successPercent = Int((successRate * 100).rounded())
        let latencyText = medianLatencyMs.map { "\(Int($0.rounded())) ms" } ?? "No latency"
        switch status {
        case .healthy:
            return LayerHealthSnapshot(
                layer: .dns,
                status: .healthy,
                score: 1,
                title: "DNS healthy",
                explanation: "DNS lookups are resolving normally across the control targets.",
                primaryMetricText: latencyText)
        case .degraded:
            return LayerHealthSnapshot(
                layer: .dns,
                status: .degraded,
                score: 0.6,
                title: "DNS degraded",
                explanation: "DNS lookups are slower or less reliable than expected.",
                primaryMetricText: "\(latencyText) · \(successPercent)% success")
        case .failed:
            return LayerHealthSnapshot(
                layer: .dns,
                status: .failed,
                score: 0,
                title: "DNS failed",
                explanation: "DNS lookups are broadly failing across the control targets.",
                primaryMetricText: "\(successPercent)% success")
        case .pending:
            return pendingLayer(.dns, explanation: "Waiting for DNS probe results.", metric: "Pending")
        case .unavailable:
            return unavailableLayer(.dns, explanation: "DNS is unavailable.")
        }
    }

    static func internetLayer(status: LayerStatus, successRate: Double,
                              medianLatencyMs: Double?) -> LayerHealthSnapshot
    {
        let successPercent = Int((successRate * 100).rounded())
        let latencyText = medianLatencyMs.map { "\(Int($0.rounded())) ms" } ?? "No latency"
        switch status {
        case .healthy:
            return LayerHealthSnapshot(
                layer: .internet,
                status: .healthy,
                score: 1,
                title: "Internet healthy",
                explanation: "Public control targets are reachable.",
                primaryMetricText: latencyText)
        case .degraded:
            return LayerHealthSnapshot(
                layer: .internet,
                status: .degraded,
                score: 0.6,
                title: "Internet degraded",
                explanation: "Public control targets are reachable, but slower or less reliable than expected.",
                primaryMetricText: "\(latencyText) · \(successPercent)% success")
        case .failed:
            return LayerHealthSnapshot(
                layer: .internet,
                status: .failed,
                score: 0,
                title: "Internet failed",
                explanation: "Public control targets are broadly failing.",
                primaryMetricText: "\(successPercent)% success")
        case .pending:
            return pendingLayer(.internet, explanation: "Waiting for internet probes.", metric: "Pending")
        case .unavailable:
            return unavailableLayer(.internet, explanation: "Internet reachability is unavailable.")
        }
    }

    static func qualityLayer(
        status: LayerStatus,
        successRate: Double,
        medianLatencyMs: Double?,
        jitterMs: Double?) -> LayerHealthSnapshot
    {
        let latencyText = medianLatencyMs.map { "\(Int($0.rounded())) ms" } ?? "No latency"
        let jitterText = jitterMs.map { "\(Int($0.rounded())) ms jitter" } ?? "No jitter"
        let successPercent = Int((successRate * 100).rounded())
        switch status {
        case .healthy:
            return LayerHealthSnapshot(
                layer: .quality,
                status: .healthy,
                score: 1,
                title: "Quality healthy",
                explanation: "Latency and jitter look stable across the control targets.",
                primaryMetricText: jitterText)
        case .degraded:
            return LayerHealthSnapshot(
                layer: .quality,
                status: .degraded,
                score: 0.6,
                title: "Quality degraded",
                explanation: "Latency or jitter is elevated across the control targets.",
                primaryMetricText: "\(latencyText) · \(jitterText) · \(successPercent)% success")
        case .failed:
            return LayerHealthSnapshot(
                layer: .quality,
                status: .failed,
                score: 0,
                title: "Quality poor",
                explanation: "The connection is technically up, but the measured quality is poor.",
                primaryMetricText: "\(latencyText) · \(jitterText)")
        case .pending:
            return pendingLayer(.quality, explanation: "Waiting for quality probes.", metric: "Pending")
        case .unavailable:
            return unavailableLayer(.quality, explanation: "Quality is unavailable.")
        }
    }

    static func pendingLayer(_ layer: HealthLayer, explanation: String, metric: String? = nil) -> LayerHealthSnapshot {
        LayerHealthSnapshot(
            layer: layer,
            status: .pending,
            score: 0,
            title: "\(layer.displayName) pending",
            explanation: explanation,
            primaryMetricText: metric)
    }

    static func unavailableLayer(_ layer: HealthLayer, explanation: String) -> LayerHealthSnapshot {
        LayerHealthSnapshot(
            layer: layer,
            status: .unavailable,
            score: 0,
            title: "\(layer.displayName) unavailable",
            explanation: explanation,
            primaryMetricText: "Unavailable")
    }
}
