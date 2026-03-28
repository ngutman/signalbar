import Foundation

enum DiagnosisResolver {
    static func diagnosis(
        dnsStatus: LayerStatus,
        internetStatus: LayerStatus,
        qualityStatus: LayerStatus,
        internetSuccessRate: Double?) -> Diagnosis
    {
        if dnsStatus == .failed {
            return Diagnosis(
                layer: .dns,
                scope: .local,
                severity: .failed,
                title: "DNS issue",
                summary: "Connected, but DNS lookups are failing.")
        }
        if internetStatus == .failed {
            return Diagnosis(
                layer: .internet,
                scope: .widespread,
                severity: .failed,
                title: "Internet issue",
                summary: "Local network and DNS are up, but public internet reachability is failing.")
        }
        if qualityStatus == .failed {
            return Diagnosis(
                layer: .quality,
                scope: .widespread,
                severity: .poor,
                title: "Poor quality",
                summary: "The connection is up, but the measured network quality is poor.")
        }
        if dnsStatus == .degraded {
            return Diagnosis(
                layer: .dns,
                scope: .local,
                severity: .degraded,
                title: "DNS degraded",
                summary: "DNS lookups are slower or less reliable than expected.")
        }
        if internetStatus == .degraded {
            let suffix = internetSuccessRate
                .map { " \(Int(($0 * 100).rounded()))% of control-target probes succeeded." } ?? ""
            return Diagnosis(
                layer: .internet,
                scope: .widespread,
                severity: .degraded,
                title: "Internet degraded",
                summary: "Public internet reachability is slower or less reliable than expected.\(suffix)")
        }
        if qualityStatus == .degraded {
            return Diagnosis(
                layer: .quality,
                scope: .widespread,
                severity: .degraded,
                title: "Flaky",
                summary: "The connection is up, but latency or jitter is elevated.")
        }
        if internetStatus == .healthy, qualityStatus == .healthy {
            return Diagnosis(
                layer: .quality,
                scope: .none,
                severity: .healthy,
                title: "Healthy",
                summary: "Link, DNS, internet reachability, and quality look normal.")
        }
        if internetStatus == .healthy {
            return Diagnosis(
                layer: .internet,
                scope: .none,
                severity: .healthy,
                title: "Internet healthy",
                summary: "Link, DNS, and internet reachability look normal.")
        }
        if dnsStatus == .healthy {
            return Diagnosis(
                layer: .dns,
                scope: .none,
                severity: .healthy,
                title: "DNS healthy",
                summary: "Local path and DNS look healthy. Internet and quality checks are pending.")
        }
        return Diagnosis(
            layer: .link,
            scope: .none,
            severity: .healthy,
            title: "Path connected",
            summary: "Local network path is connected. Additional checks are pending.")
    }

    static func withWatchedTarget(
        base: Diagnosis,
        watchedTargetHealth: TargetHealth?,
        internetStatus: LayerStatus,
        qualityStatus: LayerStatus) -> Diagnosis
    {
        guard let watchedTargetHealth, TargetHealthFactory.targetHasIssue(watchedTargetHealth) else { return base }
        guard internetStatus != .failed, qualityStatus != .failed else { return base }
        if base.severity == .healthy || base.layer == .quality || base.layer == .internet {
            return Diagnosis(
                layer: .watchedService,
                scope: .targetSpecific,
                severity: .degraded,
                title: "Service-specific issue",
                summary: "Internet looks healthy; issue appears isolated to \(watchedTargetHealth.target.name).")
        }
        return base
    }
}
