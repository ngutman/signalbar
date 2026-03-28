import Foundation
import SignalBarCore

enum MenuPresentationBuilder {
    static func presentation(for snapshot: HealthSnapshot?) -> StatusPresentation {
        guard let snapshot else {
            return StatusPresentation(
                titleText: "Starting",
                summaryText: "Waiting for initial network path state.",
                contextText: "Path monitor starting · live path mode",
                layerRows: [
                    .init(
                        layer: .link,
                        status: .pending,
                        metricText: "Pending",
                        detailText: "Waiting for initial network path state."),
                    .init(layer: .dns, status: .pending, metricText: "Pending", detailText: "Waiting for DNS probes."),
                    .init(
                        layer: .internet,
                        status: .pending,
                        metricText: "Pending",
                        detailText: "Waiting for internet probes."),
                    .init(
                        layer: .quality,
                        status: .pending,
                        metricText: "Pending",
                        detailText: "Waiting for quality probes.")
                ],
                targetRows: [],
                watchedTargetRow: nil)
        }

        return StatusPresentation(
            titleText: snapshot.diagnosis.title,
            summaryText: snapshot.diagnosis.summary,
            contextText: contextText(for: snapshot),
            layerRows: HealthLayer.allCases.map { layer in
                layerRow(for: layer, snapshot: snapshot)
            },
            targetRows: snapshot.controlTargets.map { targetRow(for: $0) },
            watchedTargetRow: snapshot.watchedTarget.map { targetRow(for: $0, labelPrefix: "Watched · ") })
    }

    private static func layerRow(for layer: HealthLayer, snapshot: HealthSnapshot) -> LayerRowViewState {
        guard let layerSnapshot = snapshot.layers.first(where: { $0.layer == layer }) else {
            return LayerRowViewState(layer: layer, status: .pending, metricText: "Pending", detailText: "No state yet.")
        }
        return LayerRowViewState(
            layer: layerSnapshot.layer,
            status: layerSnapshot.status,
            metricText: layerSnapshot.primaryMetricText ?? layerSnapshot.status.displayName,
            detailText: layerSnapshot.explanation)
    }

    private static func targetRow(for targetHealth: TargetHealth, labelPrefix: String = "") -> TargetRowViewState {
        let statusText: String
        let tone: TargetRowTone
        if let latestHTTP = targetHealth.latestHTTP {
            if latestHTTP.success {
                if let totalMs = latestHTTP.totalMs {
                    statusText = "\(Int(totalMs.rounded())) ms"
                } else if let statusCode = latestHTTP.statusCode {
                    statusText = "HTTP \(statusCode)"
                } else {
                    statusText = "Healthy"
                }
                tone = targetTone(successRate: targetHealth.successRate, jitterMs: targetHealth.jitterMs)
            } else {
                statusText = targetHealth.lastFailureText ?? "Failed"
                tone = .failed
            }
        } else if let latestDNS = targetHealth.latestDNS {
            if latestDNS.success {
                if let durationMs = latestDNS.durationMs {
                    statusText = "DNS \(Int(durationMs.rounded())) ms"
                } else {
                    statusText = "DNS healthy"
                }
                tone = targetHealth.successRate < 0.995 ? .degraded : .healthy
            } else {
                statusText = targetHealth.lastFailureText ?? "Failed"
                tone = .failed
            }
        } else {
            statusText = "Pending"
            tone = .pending
        }

        var detailParts: [String] = []
        if tone == .failed || targetHealth.successRate < 0.995 {
            detailParts.append("\(Int((targetHealth.successRate * 100).rounded()))% success")
        }
        if let jitterMs = targetHealth.jitterMs, jitterMs >= 40 {
            detailParts.append("\(Int(jitterMs.rounded())) ms jitter")
        }
        let detailText = detailParts.isEmpty ? nil : detailParts.joined(separator: " · ")

        return TargetRowViewState(
            id: targetHealth.id,
            labelText: labelPrefix + targetHealth.target.name,
            statusText: statusText,
            detailText: detailText,
            tone: tone)
    }

    private static func contextText(for snapshot: HealthSnapshot) -> String {
        guard let path = snapshot.path else {
            return "No path details yet · live path mode"
        }

        var parts: [String] = []
        switch path.status {
        case .satisfied:
            parts.append(path.interface?.displayName ?? "Connected")
            let capabilities = [path.supportsIPv4 ? "IPv4" : nil, path.supportsIPv6 ? "IPv6" : nil]
                .compactMap(\.self)
            if !capabilities.isEmpty {
                parts.append(capabilities.joined(separator: "/"))
            }
            if path.isConstrained {
                parts.append("Constrained")
            } else if path.isExpensive {
                parts.append("Expensive")
            }
        case .unsatisfied:
            parts.append("No active interface")
        case .requiresConnection:
            parts.append("Needs connection")
        }
        if parts.isEmpty {
            parts.append("Connected")
        }
        return parts.joined(separator: " · ")
    }

    private static func targetTone(successRate: Double, jitterMs: Double?) -> TargetRowTone {
        if successRate < 0.995 {
            return .degraded
        }
        if let jitterMs, jitterMs >= 40 {
            return .degraded
        }
        return .healthy
    }
}
