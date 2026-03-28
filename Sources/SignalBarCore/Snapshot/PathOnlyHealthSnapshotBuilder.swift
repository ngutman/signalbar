import Foundation

public enum PathOnlyHealthSnapshotBuilder {
    public static func makeInitialSnapshot(at date: Date = .now) -> HealthSnapshot {
        HealthSnapshot(
            generatedAt: date,
            path: nil,
            layers: [
                LayerSnapshotFactory.pendingLayer(.link, explanation: "Waiting for initial network path state."),
                LayerSnapshotFactory.pendingLayer(.dns, explanation: "Waiting for DNS probes."),
                LayerSnapshotFactory.pendingLayer(.internet, explanation: "Waiting for internet probes."),
                LayerSnapshotFactory.pendingLayer(.quality, explanation: "Waiting for quality probes.")
            ],
            controlTargets: [],
            watchedTarget: nil,
            diagnosis: Diagnosis(
                layer: .unknown,
                scope: .none,
                severity: .degraded,
                title: "Starting",
                summary: "Waiting for initial network path state."),
            isStale: false,
            overallScore: 0,
            medianLatencyMs: nil,
            jitterMs: nil,
            reliability: 0)
    }

    public static func makeSnapshot(path: PathSnapshot, at date: Date? = nil) -> HealthSnapshot {
        let generatedAt = date ?? path.observedAt
        switch path.status {
        case .satisfied:
            return HealthSnapshot(
                generatedAt: generatedAt,
                path: path,
                layers: [
                    LayerHealthSnapshot(
                        layer: .link,
                        status: .healthy,
                        score: 1,
                        title: "Link healthy",
                        explanation: "Active network path is satisfied.",
                        primaryMetricText: path.interface?.displayName ?? "Connected"),
                    LayerSnapshotFactory.pendingLayer(.dns, explanation: "Waiting for DNS probes.", metric: "Pending"),
                    LayerSnapshotFactory.pendingLayer(
                        .internet,
                        explanation: "Waiting for internet probes.",
                        metric: "Pending"),
                    LayerSnapshotFactory.pendingLayer(
                        .quality,
                        explanation: "Waiting for quality probes.",
                        metric: "Pending")
                ],
                controlTargets: [],
                watchedTarget: nil,
                diagnosis: Diagnosis(
                    layer: .link,
                    scope: .none,
                    severity: .healthy,
                    title: "Path connected",
                    summary: "Local network path is connected. DNS, internet, and quality checks are pending."),
                isStale: false,
                overallScore: 0.25,
                medianLatencyMs: nil,
                jitterMs: nil,
                reliability: 0)
        case .unsatisfied:
            return HealthSnapshot(
                generatedAt: generatedAt,
                path: path,
                layers: [
                    LayerHealthSnapshot(
                        layer: .link,
                        status: .failed,
                        score: 0,
                        title: "Link failed",
                        explanation: "No active network path is available.",
                        primaryMetricText: "No path"),
                    LayerSnapshotFactory.unavailableLayer(.dns, explanation: "DNS depends on an active path."),
                    LayerSnapshotFactory.unavailableLayer(
                        .internet,
                        explanation: "Internet reachability depends on an active path."),
                    LayerSnapshotFactory.unavailableLayer(.quality, explanation: "Quality depends on an active path.")
                ],
                controlTargets: [],
                watchedTarget: nil,
                diagnosis: Diagnosis(
                    layer: .link,
                    scope: .local,
                    severity: .offline,
                    title: "Offline",
                    summary: "No active network path is available."),
                isStale: false,
                overallScore: 0,
                medianLatencyMs: nil,
                jitterMs: nil,
                reliability: 0)
        case .requiresConnection:
            return HealthSnapshot(
                generatedAt: generatedAt,
                path: path,
                layers: [
                    LayerHealthSnapshot(
                        layer: .link,
                        status: .failed,
                        score: 0,
                        title: "Connection required",
                        explanation: "The network path requires a connection before traffic can flow.",
                        primaryMetricText: "Needs connection"),
                    LayerSnapshotFactory.unavailableLayer(.dns, explanation: "DNS depends on an active path."),
                    LayerSnapshotFactory.unavailableLayer(
                        .internet,
                        explanation: "Internet reachability depends on an active path."),
                    LayerSnapshotFactory.unavailableLayer(.quality, explanation: "Quality depends on an active path.")
                ],
                controlTargets: [],
                watchedTarget: nil,
                diagnosis: Diagnosis(
                    layer: .link,
                    scope: .local,
                    severity: .offline,
                    title: "Needs connection",
                    summary: "A network path exists, but it requires a connection before traffic can flow."),
                isStale: false,
                overallScore: 0,
                medianLatencyMs: nil,
                jitterMs: nil,
                reliability: 0)
        }
    }
}
