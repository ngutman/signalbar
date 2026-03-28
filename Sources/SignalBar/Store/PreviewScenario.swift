import Foundation
import SignalBarCore

enum PreviewScenario: String, CaseIterable, Sendable {
    case healthy
    case offline
    case dnsFailure
    case internetFailure
    case qualityDegraded
    case watchedServiceIssue
    case staleHealthy

    var displayName: String {
        switch self {
        case .healthy:
            "Healthy"
        case .offline:
            "Offline"
        case .dnsFailure:
            "DNS failure"
        case .internetFailure:
            "Internet failure"
        case .qualityDegraded:
            "Quality degraded"
        case .watchedServiceIssue:
            "Watched service issue"
        case .staleHealthy:
            "Stale healthy"
        }
    }

    var titleText: String {
        switch self {
        case .healthy, .staleHealthy:
            "Healthy"
        case .offline:
            "Offline"
        case .dnsFailure:
            "DNS issue"
        case .internetFailure:
            "Internet issue"
        case .qualityDegraded:
            "Flaky"
        case .watchedServiceIssue:
            "Service-specific issue"
        }
    }

    var summaryText: String {
        switch self {
        case .healthy:
            "Internet path looks normal"
        case .offline:
            "No active network path"
        case .dnsFailure:
            "Connected, but DNS lookups are failing"
        case .internetFailure:
            "Local network is up, but public internet reachability is failing"
        case .qualityDegraded:
            "Connection is up, but unstable or slow"
        case .watchedServiceIssue:
            "Internet looks healthy; watched service appears degraded"
        case .staleHealthy:
            "Last known state looked healthy, but the data is stale"
        }
    }

    var toolbarState: ToolbarVisualState {
        ToolbarVisualStateBuilder.toolbarState(for: snapshot(updatedAt: .now))
    }

    var presentation: StatusPresentation {
        MenuPresentationBuilder.presentation(for: snapshot(updatedAt: .now))
    }

    func snapshot(updatedAt: Date) -> HealthSnapshot {
        let layers = layerRows.map { row in
            LayerHealthSnapshot(
                layer: row.layer,
                status: row.status,
                score: score(for: row.status),
                title: "\(row.layer.displayName) \(row.status.displayName)",
                explanation: row.detailText,
                primaryMetricText: row.metricText)
        }

        return HealthSnapshot(
            generatedAt: updatedAt,
            path: pathSnapshot(at: updatedAt),
            layers: layers,
            controlTargets: [],
            watchedTarget: previewWatchedTarget(at: updatedAt),
            diagnosis: Diagnosis(
                layer: diagnosisLayer,
                scope: diagnosisScope,
                severity: diagnosisSeverity,
                title: titleText,
                summary: summaryText),
            isStale: self == .staleHealthy,
            overallScore: overallScore(for: layers),
            medianLatencyMs: previewMedianLatencyMs,
            jitterMs: previewJitterMs,
            reliability: previewReliability)
    }

    func historySnapshot(window: HistoryWindow, updatedAt: Date) -> HistorySnapshot {
        let startDate = updatedAt.addingTimeInterval(-window.duration)
        return HistorySnapshot(
            generatedAt: updatedAt,
            window: window,
            startDate: startDate,
            endDate: updatedAt,
            layerTimelines: HealthLayer.allCases.map { layer in
                LayerTimeline(
                    layer: layer,
                    segments: timelineSegments(for: layer, startDate: startDate, endDate: updatedAt))
            },
            pingTimeline: metricTimeline(for: .ping, window: window, updatedAt: updatedAt),
            jitterTimeline: metricTimeline(for: .jitter, window: window, updatedAt: updatedAt),
            reliabilityTimeline: metricTimeline(for: .reliability, window: window, updatedAt: updatedAt),
            metricBreakdowns: [
                metricBreakdown(for: .ping, window: window, updatedAt: updatedAt),
                metricBreakdown(for: .jitter, window: window, updatedAt: updatedAt),
                metricBreakdown(for: .reliability, window: window, updatedAt: updatedAt)
            ])
    }

    var layerRows: [LayerRowViewState] {
        switch self {
        case .healthy:
            [
                .init(layer: .link, status: .healthy, metricText: "Wi-Fi", detailText: "Active path is satisfied."),
                .init(
                    layer: .dns,
                    status: .healthy,
                    metricText: "22 ms",
                    detailText: "Lookups are resolving normally."),
                .init(
                    layer: .internet,
                    status: .healthy,
                    metricText: "99% success",
                    detailText: "Control targets are reachable."),
                .init(layer: .quality, status: .healthy, metricText: "14 ms jitter", detailText: "Latency is stable.")
            ]
        case .offline:
            [
                .init(
                    layer: .link,
                    status: .failed,
                    metricText: "No path",
                    detailText: "No active network path is available."),
                .init(
                    layer: .dns,
                    status: .unavailable,
                    metricText: "Unavailable",
                    detailText: "DNS depends on an active path."),
                .init(
                    layer: .internet,
                    status: .unavailable,
                    metricText: "Unavailable",
                    detailText: "Reachability cannot be measured offline."),
                .init(
                    layer: .quality,
                    status: .unavailable,
                    metricText: "Unavailable",
                    detailText: "Quality depends on a reachable path.")
            ]
        case .dnsFailure:
            [
                .init(layer: .link, status: .healthy, metricText: "Wi-Fi", detailText: "Local path is connected."),
                .init(
                    layer: .dns,
                    status: .failed,
                    metricText: "Timeouts",
                    detailText: "DNS lookups are broadly failing."),
                .init(
                    layer: .internet,
                    status: .unavailable,
                    metricText: "Blocked by DNS",
                    detailText: "Public probes depend on DNS resolution."),
                .init(
                    layer: .quality,
                    status: .unavailable,
                    metricText: "Unavailable",
                    detailText: "Quality cannot be judged while DNS is down.")
            ]
        case .internetFailure:
            [
                .init(layer: .link, status: .healthy, metricText: "Wi-Fi", detailText: "Local path is connected."),
                .init(layer: .dns, status: .healthy, metricText: "24 ms", detailText: "Lookups are succeeding."),
                .init(
                    layer: .internet,
                    status: .failed,
                    metricText: "33% success",
                    detailText: "Control targets are broadly failing."),
                .init(
                    layer: .quality,
                    status: .unavailable,
                    metricText: "Unavailable",
                    detailText: "Quality depends on public reachability.")
            ]
        case .qualityDegraded:
            [
                .init(layer: .link, status: .healthy, metricText: "Wi-Fi", detailText: "Local path is connected."),
                .init(layer: .dns, status: .healthy, metricText: "26 ms", detailText: "Lookups are succeeding."),
                .init(
                    layer: .internet,
                    status: .healthy,
                    metricText: "95% success",
                    detailText: "Control targets are mostly reachable."),
                .init(
                    layer: .quality,
                    status: .degraded,
                    metricText: "91 ms jitter",
                    detailText: "Latency is unstable across targets.")
            ]
        case .watchedServiceIssue:
            [
                .init(layer: .link, status: .healthy, metricText: "Wi-Fi", detailText: "Local path is connected."),
                .init(
                    layer: .dns,
                    status: .healthy,
                    metricText: "19 ms",
                    detailText: "Lookups are resolving normally."),
                .init(
                    layer: .internet,
                    status: .healthy,
                    metricText: "100% success",
                    detailText: "Public control targets are healthy."),
                .init(
                    layer: .quality,
                    status: .healthy,
                    metricText: "11 ms jitter",
                    detailText: "Core path quality is stable.")
            ]
        case .staleHealthy:
            [
                .init(
                    layer: .link,
                    status: .healthy,
                    metricText: "Wi-Fi",
                    detailText: "Last known path state was satisfied."),
                .init(
                    layer: .dns,
                    status: .healthy,
                    metricText: "23 ms",
                    detailText: "Last known DNS behavior looked normal."),
                .init(
                    layer: .internet,
                    status: .healthy,
                    metricText: "98% success",
                    detailText: "Last known reachability looked normal."),
                .init(
                    layer: .quality,
                    status: .healthy,
                    metricText: "16 ms jitter",
                    detailText: "Last known quality looked stable.")
            ]
        }
    }

    private var diagnosisLayer: DiagnosisLayer {
        switch self {
        case .healthy, .staleHealthy:
            .quality
        case .offline:
            .link
        case .dnsFailure:
            .dns
        case .internetFailure:
            .internet
        case .qualityDegraded:
            .quality
        case .watchedServiceIssue:
            .watchedService
        }
    }

    private var diagnosisScope: DiagnosisScope {
        switch self {
        case .healthy, .staleHealthy:
            .none
        case .offline, .dnsFailure:
            .local
        case .internetFailure, .qualityDegraded:
            .widespread
        case .watchedServiceIssue:
            .targetSpecific
        }
    }

    private var diagnosisSeverity: DiagnosisSeverity {
        switch self {
        case .healthy, .staleHealthy:
            .healthy
        case .offline:
            .offline
        case .dnsFailure, .internetFailure:
            .failed
        case .qualityDegraded, .watchedServiceIssue:
            .degraded
        }
    }

    private var previewMedianLatencyMs: Double? {
        switch self {
        case .healthy, .staleHealthy, .watchedServiceIssue:
            50
        case .offline, .dnsFailure:
            nil
        case .internetFailure:
            160
        case .qualityDegraded:
            130
        }
    }

    private var previewJitterMs: Double? {
        switch self {
        case .healthy:
            14
        case .offline, .dnsFailure, .internetFailure:
            nil
        case .qualityDegraded:
            91
        case .watchedServiceIssue:
            11
        case .staleHealthy:
            16
        }
    }

    private var previewReliability: Double {
        switch self {
        case .healthy, .watchedServiceIssue:
            1.0
        case .offline, .dnsFailure:
            0
        case .internetFailure:
            0.33
        case .qualityDegraded:
            0.95
        case .staleHealthy:
            0.98
        }
    }

    private func pathSnapshot(at updatedAt: Date) -> PathSnapshot {
        switch self {
        case .offline:
            PathSnapshot(
                observedAt: updatedAt,
                status: .unsatisfied,
                interface: nil,
                isConstrained: false,
                isExpensive: false,
                supportsDNS: false,
                supportsIPv4: false,
                supportsIPv6: false)
        case .healthy, .dnsFailure, .internetFailure, .qualityDegraded, .watchedServiceIssue, .staleHealthy:
            PathSnapshot(
                observedAt: updatedAt,
                status: .satisfied,
                interface: .wifi,
                isConstrained: false,
                isExpensive: false,
                supportsDNS: true,
                supportsIPv4: true,
                supportsIPv6: true)
        }
    }

    private func previewWatchedTarget(at updatedAt: Date) -> TargetHealth? {
        guard self == .watchedServiceIssue else { return nil }
        let target = ProbeTarget(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            kind: .watched,
            name: "GitHub",
            url: URL(string: "https://github.com")!,
            method: .auto,
            interval: 15,
            timeout: 3.0)
        return TargetHealth(
            id: target.id,
            target: target,
            medianLatencyMs: nil,
            jitterMs: nil,
            successRate: 0,
            lastFailureText: "Timeout",
            latestHTTP: HTTPProbeResult(
                targetID: target.id,
                startedAt: updatedAt,
                dnsMs: 8,
                connectMs: 14,
                tlsMs: nil,
                firstByteMs: nil,
                totalMs: 3000,
                statusCode: nil,
                success: false,
                reusedConnection: false,
                failure: .timeout),
            latestDNS: nil)
    }

    private func score(for status: LayerStatus) -> Double {
        switch status {
        case .healthy:
            1.0
        case .degraded:
            0.6
        case .failed, .pending, .unavailable:
            0.0
        }
    }

    private func overallScore(for layers: [LayerHealthSnapshot]) -> Double {
        guard !layers.isEmpty else { return 0 }
        return layers.reduce(0) { $0 + $1.score } / Double(layers.count)
    }

    private func metricTimeline(for metric: HistoryMetric, window: HistoryWindow, updatedAt: Date) -> MetricTimeline {
        let startDate = updatedAt.addingTimeInterval(-window.duration)
        let samples = metricSamples(for: metric)
        let stepDuration = window.duration / Double(max(samples.count - 1, 1))
        let points = samples.enumerated().map { index, sample in
            MetricPoint(
                date: startDate.addingTimeInterval(Double(index) * stepDuration),
                value: sample.value,
                qualityBand: sample.band,
                hadFailure: sample.hadFailure)
        }
        let values = points.compactMap(\.value)
        return MetricTimeline(
            metric: metric,
            points: points,
            latestValue: points.last?.value,
            medianValue: median(of: values),
            unitText: metric.unitText)
    }

    private func metricSamples(for metric: HistoryMetric) -> [(
        value: Double?,
        band: MetricQualityBand,
        hadFailure: Bool)]
    {
        switch (self, metric) {
        case (.healthy, .ping):
            [(48, .good, false), (52, .good, false), (46, .good, false), (55, .good, false), (50, .good, false)]
        case (.healthy, .jitter):
            [(9, .good, false), (12, .good, false), (8, .good, false), (11, .good, false), (10, .good, false)]
        case (.healthy, .reliability):
            [(100, .good, false), (100, .good, false), (100, .good, false), (100, .good, false), (100, .good, false)]
        case (.offline, .ping), (.offline, .jitter), (.offline, .reliability):
            [
                (nil, .unavailable, true),
                (nil, .unavailable, true),
                (nil, .unavailable, true),
                (nil, .unavailable, true),
                (nil, .unavailable, true)
            ]
        case (.dnsFailure, .ping):
            [
                (52, .good, false),
                (54, .good, false),
                (nil, .unavailable, true),
                (nil, .unavailable, true),
                (nil, .unavailable, true)
            ]
        case (.dnsFailure, .jitter):
            [
                (10, .good, false),
                (11, .good, false),
                (nil, .unavailable, true),
                (nil, .unavailable, true),
                (nil, .unavailable, true)
            ]
        case (.dnsFailure, .reliability):
            [(100, .good, false), (100, .good, false), (0, .bad, true), (0, .bad, true), (0, .bad, true)]
        case (.internetFailure, .ping):
            [
                (56, .good, false),
                (84, .okay, false),
                (160, .degraded, true),
                (nil, .unavailable, true),
                (nil, .unavailable, true)
            ]
        case (.internetFailure, .jitter):
            [
                (12, .good, false),
                (18, .okay, false),
                (30, .degraded, true),
                (nil, .unavailable, true),
                (nil, .unavailable, true)
            ]
        case (.internetFailure, .reliability):
            [(100, .good, false), (94, .degraded, true), (62, .bad, true), (18, .bad, true), (0, .bad, true)]
        case (.qualityDegraded, .ping):
            [
                (58, .good, false),
                (112, .okay, false),
                (146, .degraded, false),
                (88, .okay, false),
                (130, .degraded, false)
            ]
        case (.qualityDegraded, .jitter):
            [(14, .good, false), (28, .okay, false), (66, .bad, false), (42, .degraded, false), (91, .bad, false)]
        case (.qualityDegraded, .reliability):
            [(100, .good, false), (100, .good, false), (96, .okay, false), (95, .okay, false), (95, .okay, false)]
        case (.watchedServiceIssue, .ping):
            [(50, .good, false), (53, .good, false), (48, .good, false), (51, .good, false), (49, .good, false)]
        case (.watchedServiceIssue, .jitter):
            [(9, .good, false), (11, .good, false), (10, .good, false), (12, .good, false), (11, .good, false)]
        case (.watchedServiceIssue, .reliability):
            [(100, .good, false), (100, .good, false), (100, .good, false), (100, .good, false), (100, .good, false)]
        case (.staleHealthy, .ping):
            [(50, .good, false), (49, .good, false), (51, .good, false), (52, .good, false), (50, .good, false)]
        case (.staleHealthy, .jitter):
            [(10, .good, false), (12, .good, false), (11, .good, false), (13, .good, false), (10, .good, false)]
        case (.staleHealthy, .reliability):
            [(99, .good, false), (99, .good, false), (99, .good, false), (99, .good, false), (99, .good, false)]
        case (_, .overview):
            []
        }
    }

    private func metricBreakdown(for metric: HistoryMetric, window: HistoryWindow, updatedAt: Date) -> MetricBreakdown {
        let startDate = updatedAt.addingTimeInterval(-window.duration)
        let sources = breakdownSources(for: metric)
        let stepDuration = window.duration / Double(max((sources.first?.value.count ?? 1) - 1, 1))

        let series = sources.map { label, samples in
            let points = samples.enumerated().map { index, sample in
                MetricPoint(
                    date: startDate.addingTimeInterval(Double(index) * stepDuration),
                    value: sample.value,
                    qualityBand: sample.band,
                    hadFailure: sample.hadFailure)
            }
            return MetricBreakdownSeries(
                label: label,
                points: points,
                latestValue: points.last?.value,
                unitText: metric.unitText)
        }

        let bucketDetails: [MetricBucketDetail] = (0 ..< max((sources.first?.value.count ?? 0), 0)).map { index in
            let date = startDate.addingTimeInterval(Double(index) * stepDuration)
            let contributions = sources.map { label, samples in
                let sample = samples[index]
                return MetricBucketContribution(
                    label: label,
                    value: sample.value,
                    unitText: metric.unitText,
                    qualityBand: sample.band,
                    hadFailure: sample.hadFailure,
                    failureText: sample.hadFailure ? "Issue" : nil)
            }
            return MetricBucketDetail(
                metric: metric,
                date: date,
                aggregateValue: metricSamples(for: metric)[index].value,
                unitText: metric.unitText,
                contributions: contributions)
        }

        return MetricBreakdown(metric: metric, series: series, bucketDetails: bucketDetails)
    }

    private func breakdownSources(for metric: HistoryMetric) -> [(
        key: String,
        value: [(value: Double?, band: MetricQualityBand, hadFailure: Bool)])]
    {
        switch (self, metric) {
        case (.healthy, .ping):
            [
                ("Apple", [
                    (44, .good, false),
                    (48, .good, false),
                    (45, .good, false),
                    (52, .good, false),
                    (47, .good, false)
                ]),
                (
                    "Cloudflare",
                    [
                        (49, .good, false),
                        (52, .good, false),
                        (46, .good, false),
                        (55, .good, false),
                        (50, .good, false)
                    ]),
                (
                    "Google",
                    [
                        (53, .good, false),
                        (56, .good, false),
                        (49, .good, false),
                        (58, .good, false),
                        (54, .good, false)
                    ])
            ]
        case (.healthy, .jitter):
            [
                ("Apple", [
                    (7, .good, false),
                    (9, .good, false),
                    (8, .good, false),
                    (10, .good, false),
                    (9, .good, false)
                ]),
                (
                    "Cloudflare",
                    [
                        (10, .good, false),
                        (12, .good, false),
                        (8, .good, false),
                        (11, .good, false),
                        (10, .good, false)
                    ]),
                (
                    "Google",
                    [(12, .good, false), (14, .good, false), (9, .good, false), (12, .good, false), (11, .good, false)])
            ]
        case (.healthy, .reliability):
            [
                ("Apple", [
                    (100, .good, false),
                    (100, .good, false),
                    (100, .good, false),
                    (100, .good, false),
                    (100, .good, false)
                ]),
                (
                    "Cloudflare",
                    [
                        (100, .good, false),
                        (100, .good, false),
                        (100, .good, false),
                        (100, .good, false),
                        (100, .good, false)
                    ]),
                (
                    "Google",
                    [
                        (100, .good, false),
                        (100, .good, false),
                        (100, .good, false),
                        (100, .good, false),
                        (100, .good, false)
                    ])
            ]
        case (.qualityDegraded, .ping):
            [
                ("Apple", [
                    (52, .good, false),
                    (80, .okay, false),
                    (136, .degraded, false),
                    (76, .okay, false),
                    (122, .degraded, false)
                ]),
                (
                    "Cloudflare",
                    [
                        (58, .good, false),
                        (115, .okay, false),
                        (152, .degraded, false),
                        (89, .okay, false),
                        (132, .degraded, false)
                    ]),
                (
                    "Google",
                    [
                        (64, .okay, false),
                        (142, .degraded, false),
                        (170, .degraded, false),
                        (99, .okay, false),
                        (146, .degraded, false)
                    ])
            ]
        case (.qualityDegraded, .jitter):
            [
                ("Apple", [
                    (10, .good, false),
                    (18, .okay, false),
                    (40, .degraded, false),
                    (28, .okay, false),
                    (55, .degraded, false)
                ]),
                (
                    "Cloudflare",
                    [
                        (14, .good, false),
                        (26, .okay, false),
                        (62, .bad, false),
                        (35, .degraded, false),
                        (78, .bad, false)
                    ]),
                (
                    "Google",
                    [
                        (18, .okay, false),
                        (34, .degraded, false),
                        (71, .bad, false),
                        (44, .degraded, false),
                        (91, .bad, false)
                    ])
            ]
        case (.qualityDegraded, .reliability):
            [
                ("Apple", [
                    (100, .good, false),
                    (100, .good, false),
                    (98, .okay, false),
                    (97, .okay, false),
                    (96, .okay, false)
                ]),
                (
                    "Cloudflare",
                    [
                        (100, .good, false),
                        (100, .good, false),
                        (95, .okay, false),
                        (94, .degraded, false),
                        (94, .degraded, false)
                    ]),
                (
                    "Google",
                    [
                        (100, .good, false),
                        (100, .good, false),
                        (96, .okay, false),
                        (95, .okay, false),
                        (95, .okay, false)
                    ])
            ]
        case (.internetFailure, .ping):
            [
                ("Apple", [
                    (50, .good, false),
                    (70, .okay, false),
                    (130, .degraded, true),
                    (nil, .unavailable, true),
                    (nil, .unavailable, true)
                ]),
                (
                    "Cloudflare",
                    [
                        (58, .good, false),
                        (84, .okay, false),
                        (170, .degraded, true),
                        (nil, .unavailable, true),
                        (nil, .unavailable, true)
                    ]),
                (
                    "Google",
                    [
                        (60, .okay, false),
                        (98, .okay, false),
                        (180, .degraded, true),
                        (nil, .unavailable, true),
                        (nil, .unavailable, true)
                    ])
            ]
        case (.internetFailure, .jitter):
            [
                ("Apple", [
                    (10, .good, false),
                    (16, .okay, false),
                    (28, .okay, true),
                    (nil, .unavailable, true),
                    (nil, .unavailable, true)
                ]),
                (
                    "Cloudflare",
                    [
                        (12, .good, false),
                        (20, .okay, false),
                        (36, .degraded, true),
                        (nil, .unavailable, true),
                        (nil, .unavailable, true)
                    ]),
                (
                    "Google",
                    [
                        (14, .good, false),
                        (22, .okay, false),
                        (42, .degraded, true),
                        (nil, .unavailable, true),
                        (nil, .unavailable, true)
                    ])
            ]
        case (.internetFailure, .reliability):
            [
                ("Apple", [
                    (100, .good, false),
                    (90, .degraded, true),
                    (65, .bad, true),
                    (20, .bad, true),
                    (0, .bad, true)
                ]),
                (
                    "Cloudflare",
                    [(100, .good, false), (94, .degraded, true), (58, .bad, true), (16, .bad, true), (0, .bad, true)]),
                (
                    "Google",
                    [(100, .good, false), (98, .okay, true), (63, .bad, true), (18, .bad, true), (0, .bad, true)])
            ]
        case (.dnsFailure, .ping), (.dnsFailure, .jitter):
            [
                ("Apple", [
                    (52, .good, false),
                    (54, .good, false),
                    (nil, .unavailable, true),
                    (nil, .unavailable, true),
                    (nil, .unavailable, true)
                ]),
                (
                    "Cloudflare",
                    [
                        (51, .good, false),
                        (53, .good, false),
                        (nil, .unavailable, true),
                        (nil, .unavailable, true),
                        (nil, .unavailable, true)
                    ]),
                (
                    "Google",
                    [
                        (55, .good, false),
                        (56, .good, false),
                        (nil, .unavailable, true),
                        (nil, .unavailable, true),
                        (nil, .unavailable, true)
                    ])
            ]
        case (.dnsFailure, .reliability):
            [
                ("Apple", [
                    (100, .good, false),
                    (100, .good, false),
                    (0, .bad, true),
                    (0, .bad, true),
                    (0, .bad, true)
                ]),
                (
                    "Cloudflare",
                    [(100, .good, false), (100, .good, false), (0, .bad, true), (0, .bad, true), (0, .bad, true)]),
                (
                    "Google",
                    [(100, .good, false), (100, .good, false), (0, .bad, true), (0, .bad, true), (0, .bad, true)])
            ]
        case (.watchedServiceIssue, .ping):
            [
                ("Apple", [
                    (48, .good, false),
                    (51, .good, false),
                    (46, .good, false),
                    (50, .good, false),
                    (48, .good, false)
                ]),
                (
                    "Cloudflare",
                    [
                        (50, .good, false),
                        (53, .good, false),
                        (48, .good, false),
                        (51, .good, false),
                        (49, .good, false)
                    ]),
                (
                    "Google",
                    [
                        (52, .good, false),
                        (55, .good, false),
                        (50, .good, false),
                        (53, .good, false),
                        (51, .good, false)
                    ]),
                (
                    "GitHub",
                    [
                        (nil, .unavailable, true),
                        (nil, .unavailable, true),
                        (nil, .unavailable, true),
                        (nil, .unavailable, true),
                        (nil, .unavailable, true)
                    ])
            ]
        case (.watchedServiceIssue, .jitter):
            [
                ("Apple", [
                    (8, .good, false),
                    (10, .good, false),
                    (9, .good, false),
                    (11, .good, false),
                    (10, .good, false)
                ]),
                (
                    "Cloudflare",
                    [
                        (9, .good, false),
                        (11, .good, false),
                        (10, .good, false),
                        (12, .good, false),
                        (11, .good, false)
                    ]),
                (
                    "Google",
                    [
                        (10, .good, false),
                        (12, .good, false),
                        (11, .good, false),
                        (13, .good, false),
                        (12, .good, false)
                    ]),
                (
                    "GitHub",
                    [
                        (nil, .unavailable, true),
                        (nil, .unavailable, true),
                        (nil, .unavailable, true),
                        (nil, .unavailable, true),
                        (nil, .unavailable, true)
                    ])
            ]
        case (.watchedServiceIssue, .reliability):
            [
                ("Apple", [
                    (100, .good, false),
                    (100, .good, false),
                    (100, .good, false),
                    (100, .good, false),
                    (100, .good, false)
                ]),
                (
                    "Cloudflare",
                    [
                        (100, .good, false),
                        (100, .good, false),
                        (100, .good, false),
                        (100, .good, false),
                        (100, .good, false)
                    ]),
                (
                    "Google",
                    [
                        (100, .good, false),
                        (100, .good, false),
                        (100, .good, false),
                        (100, .good, false),
                        (100, .good, false)
                    ]),
                ("GitHub", [(0, .bad, true), (0, .bad, true), (0, .bad, true), (0, .bad, true), (0, .bad, true)])
            ]
        case (.offline, _):
            [
                ("Apple", [
                    (nil, .unavailable, true),
                    (nil, .unavailable, true),
                    (nil, .unavailable, true),
                    (nil, .unavailable, true),
                    (nil, .unavailable, true)
                ]),
                (
                    "Cloudflare",
                    [
                        (nil, .unavailable, true),
                        (nil, .unavailable, true),
                        (nil, .unavailable, true),
                        (nil, .unavailable, true),
                        (nil, .unavailable, true)
                    ]),
                (
                    "Google",
                    [
                        (nil, .unavailable, true),
                        (nil, .unavailable, true),
                        (nil, .unavailable, true),
                        (nil, .unavailable, true),
                        (nil, .unavailable, true)
                    ])
            ]
        case (.staleHealthy, .ping):
            [
                ("Apple", [
                    (49, .good, false),
                    (47, .good, false),
                    (50, .good, false),
                    (51, .good, false),
                    (49, .good, false)
                ]),
                (
                    "Cloudflare",
                    [
                        (50, .good, false),
                        (49, .good, false),
                        (51, .good, false),
                        (52, .good, false),
                        (50, .good, false)
                    ]),
                (
                    "Google",
                    [
                        (51, .good, false),
                        (50, .good, false),
                        (52, .good, false),
                        (53, .good, false),
                        (51, .good, false)
                    ])
            ]
        case (.staleHealthy, .jitter):
            [
                ("Apple", [
                    (9, .good, false),
                    (10, .good, false),
                    (11, .good, false),
                    (12, .good, false),
                    (10, .good, false)
                ]),
                (
                    "Cloudflare",
                    [
                        (10, .good, false),
                        (11, .good, false),
                        (12, .good, false),
                        (13, .good, false),
                        (11, .good, false)
                    ]),
                (
                    "Google",
                    [
                        (11, .good, false),
                        (12, .good, false),
                        (13, .good, false),
                        (14, .good, false),
                        (12, .good, false)
                    ])
            ]
        case (.staleHealthy, .reliability):
            [
                ("Apple", [
                    (99, .good, false),
                    (99, .good, false),
                    (99, .good, false),
                    (99, .good, false),
                    (99, .good, false)
                ]),
                (
                    "Cloudflare",
                    [
                        (99, .good, false),
                        (99, .good, false),
                        (99, .good, false),
                        (99, .good, false),
                        (99, .good, false)
                    ]),
                (
                    "Google",
                    [
                        (99, .good, false),
                        (99, .good, false),
                        (99, .good, false),
                        (99, .good, false),
                        (99, .good, false)
                    ])
            ]
        default:
            []
        }
    }

    private func median(of values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sortedValues = values.sorted()
        let middleIndex = sortedValues.count / 2
        if sortedValues.count.isMultiple(of: 2) {
            return (sortedValues[middleIndex - 1] + sortedValues[middleIndex]) / 2
        }
        return sortedValues[middleIndex]
    }

    private func timelineSegments(for layer: HealthLayer, startDate: Date, endDate: Date) -> [LayerTimelineSegment] {
        let duration = endDate.timeIntervalSince(startDate)
        let segmentDefinitions: [(Double, LayerStatus)] = switch self {
        case .healthy, .staleHealthy:
            [(0.0, .healthy)]
        case .offline:
            switch layer {
            case .link:
                [(0.0, .healthy), (0.72, .failed)]
            case .dns, .internet, .quality:
                [(0.0, .healthy), (0.72, .unavailable)]
            }
        case .dnsFailure:
            switch layer {
            case .link:
                [(0.0, .healthy)]
            case .dns:
                [(0.0, .healthy), (0.64, .degraded), (0.82, .failed)]
            case .internet, .quality:
                [(0.0, .healthy), (0.82, .unavailable)]
            }
        case .internetFailure:
            switch layer {
            case .link, .dns:
                [(0.0, .healthy)]
            case .internet:
                [(0.0, .healthy), (0.7, .degraded), (0.86, .failed)]
            case .quality:
                [(0.0, .healthy), (0.86, .unavailable)]
            }
        case .qualityDegraded:
            switch layer {
            case .link, .dns, .internet:
                [(0.0, .healthy)]
            case .quality:
                [(0.0, .healthy), (0.55, .degraded), (0.76, .healthy), (0.88, .degraded)]
            }
        case .watchedServiceIssue:
            [(0.0, .healthy)]
        }

        let points = segmentDefinitions.enumerated().map { index, segment in
            let startFraction = min(max(segment.0, 0), 1)
            let segmentStart = startDate.addingTimeInterval(duration * startFraction)
            let segmentEnd: Date = {
                guard index + 1 < segmentDefinitions.count else { return endDate }
                let nextFraction = min(max(segmentDefinitions[index + 1].0, 0), 1)
                return startDate.addingTimeInterval(duration * nextFraction)
            }()
            return LayerTimelineSegment(startDate: segmentStart, endDate: segmentEnd, status: segment.1)
        }

        return points.filter { $0.endDate > $0.startDate }
    }
}
