import Foundation

enum TargetHealthFactory {
    static func makeTargetHealth(
        target: ProbeTarget,
        dnsHistory: [DNSProbeResult],
        httpHistory: [HTTPProbeResult]) -> TargetHealth
    {
        let latestDNS = dnsHistory.last
        let latestHTTP = httpHistory.last
        let httpSuccesses = httpHistory.filter(\.success)
        let medianLatencyMs = SnapshotStatistics.median(of: httpSuccesses.compactMap(\.totalMs))
            ?? SnapshotStatistics.median(of: dnsHistory.filter(\.success).compactMap(\.durationMs))
        let jitterMs = SnapshotStatistics.jitter(of: httpSuccesses)
        let successRate = !httpHistory.isEmpty
            ? SnapshotStatistics.successRate(for: httpHistory)
            : SnapshotStatistics.successRate(for: dnsHistory)
        let lastFailureText = failureText(latestHTTP: latestHTTP, latestDNS: latestDNS)
        return TargetHealth(
            id: target.id,
            target: target,
            medianLatencyMs: medianLatencyMs,
            jitterMs: jitterMs,
            successRate: successRate,
            lastFailureText: lastFailureText,
            latestHTTP: latestHTTP,
            latestDNS: latestDNS)
    }

    static func targetHasIssue(_ targetHealth: TargetHealth) -> Bool {
        if let latestHTTP = targetHealth.latestHTTP {
            return !latestHTTP.success
        }
        if let latestDNS = targetHealth.latestDNS {
            return !latestDNS.success
        }
        return false
    }

    static func aggregateJitter(for targetHealths: [TargetHealth]) -> Double? {
        SnapshotStatistics.median(of: targetHealths.compactMap(\.jitterMs))
    }

    private static func failureText(latestHTTP: HTTPProbeResult?, latestDNS: DNSProbeResult?) -> String? {
        if let latestHTTP, !latestHTTP.success {
            if let statusCode = latestHTTP.statusCode {
                return "HTTP \(statusCode)"
            }
            if let failure = latestHTTP.failure {
                switch failure {
                case .dns:
                    return "DNS failure"
                case .connect:
                    return "Connect failure"
                case .tls:
                    return "TLS failure"
                case .timeout:
                    return "Timeout"
                case .badStatus:
                    return "Bad status"
                case .cancelled:
                    return "Cancelled"
                case .unknown:
                    return "Unknown error"
                }
            }
            return "Failed"
        }
        if let latestDNS, !latestDNS.success {
            switch latestDNS.failure {
            case .timeout:
                return "Timeout"
            case .noRecords:
                return "No records"
            case .resolverFailure:
                return "Resolver failure"
            case .cancelled:
                return "Cancelled"
            case .unknown:
                return "Unknown error"
            case nil:
                return "Failed"
            }
        }
        return nil
    }
}
