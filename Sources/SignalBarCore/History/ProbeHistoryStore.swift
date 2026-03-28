import Foundation

struct ProbeHistoryStore: Sendable {
    private struct Contribution: Sendable, Equatable {
        let label: String
        let metric: HistoryMetric
        let value: Double?
        let hadFailure: Bool
        let failureText: String?
    }

    private struct Sample: Sendable, Equatable {
        let date: Date
        let statuses: [HealthLayer: LayerStatus]
        let pingMs: Double?
        let jitterMs: Double?
        let reliabilityPercent: Double?
        let hadFailure: Bool
        let contributions: [Contribution]

        func status(for layer: HealthLayer) -> LayerStatus {
            statuses[layer] ?? .pending
        }

        func value(for metric: HistoryMetric) -> Double? {
            switch metric {
            case .ping:
                pingMs
            case .jitter:
                jitterMs
            case .reliability:
                reliabilityPercent
            case .overview:
                nil
            }
        }

        func contributions(for metric: HistoryMetric) -> [Contribution] {
            contributions.filter { $0.metric == metric }
        }
    }

    private struct Bucket: Sendable, Equatable {
        let startDate: Date
        let endDate: Date
        let samples: [Sample]
    }

    private let retentionDuration: TimeInterval
    private var samples: [Sample] = []

    init(retentionDuration: TimeInterval = HistoryWindow.sixtyMinutes.duration + (5 * 60)) {
        self.retentionDuration = retentionDuration
    }

    mutating func record(_ snapshot: HealthSnapshot) {
        let statuses = Dictionary(uniqueKeysWithValues: snapshot.layers.map { ($0.layer, $0.status) })
        let allTargets = snapshot.controlTargets + [snapshot.watchedTarget].compactMap(\.self)
        let latestSuccessfulHTTPDurations = allTargets.compactMap { targetHealth -> Double? in
            guard let latestHTTP = targetHealth.latestHTTP, latestHTTP.success else { return nil }
            return latestHTTP.totalMs
        }
        let hasHTTPEvidence = allTargets.contains { $0.latestHTTP != nil }
        let hadFailure = allTargets.contains { $0.latestHTTP?.success == false }

        samples.append(
            Sample(
                date: snapshot.generatedAt,
                statuses: statuses,
                pingMs: median(of: latestSuccessfulHTTPDurations),
                jitterMs: snapshot.jitterMs,
                reliabilityPercent: hasHTTPEvidence ? snapshot.reliability * 100 : nil,
                hadFailure: hadFailure,
                contributions: contributions(for: snapshot, targets: allTargets)))
        prune(now: snapshot.generatedAt)
    }

    mutating func reset() {
        samples.removeAll()
    }

    func historySnapshot(for window: HistoryWindow, at date: Date = .now) -> HistorySnapshot {
        let startDate = date.addingTimeInterval(-window.duration)
        let priorSample = samples.last(where: { $0.date < startDate })
        let inWindowSamples = samples
            .filter { $0.date >= startDate && $0.date <= date }
            .sorted { $0.date < $1.date }

        if priorSample == nil, inWindowSamples.isEmpty {
            return .placeholder(window: window, at: date)
        }

        let buckets = buckets(for: window, startDate: startDate, endDate: date, samples: inWindowSamples)
        let layerTimelines = HealthLayer.allCases.map { layer in
            LayerTimeline(
                layer: layer,
                segments: bucketedSegments(
                    for: layer,
                    buckets: buckets,
                    priorSample: priorSample))
        }

        let metricBreakdowns = [HistoryMetric.ping, .jitter, .reliability].map { metric in
            metricBreakdown(for: metric, buckets: buckets)
        }

        return HistorySnapshot(
            generatedAt: date,
            window: window,
            startDate: startDate,
            endDate: date,
            layerTimelines: layerTimelines,
            pingTimeline: metricTimeline(for: .ping, buckets: buckets),
            jitterTimeline: metricTimeline(for: .jitter, buckets: buckets),
            reliabilityTimeline: metricTimeline(for: .reliability, buckets: buckets),
            metricBreakdowns: metricBreakdowns)
    }

    private mutating func prune(now: Date) {
        let cutoff = now.addingTimeInterval(-retentionDuration)
        samples.removeAll { $0.date < cutoff }
    }

    private func contributions(for snapshot: HealthSnapshot, targets: [TargetHealth]) -> [Contribution] {
        targets.flatMap { targetHealth in
            let hasReliabilityEvidence = targetHealth.latestHTTP != nil || targetHealth.latestDNS != nil
            let latestHTTPFailure = targetHealth.latestHTTP?.success == false
            let latestDNSFailure = targetHealth.latestDNS?.success == false
            let failureText = targetHealth.lastFailureText

            return [
                Contribution(
                    label: targetHealth.target.name,
                    metric: .ping,
                    value: targetHealth.latestHTTP?.success == true ? targetHealth.latestHTTP?.totalMs : nil,
                    hadFailure: latestHTTPFailure,
                    failureText: latestHTTPFailure ? failureText : nil),
                Contribution(
                    label: targetHealth.target.name,
                    metric: .jitter,
                    value: targetHealth.jitterMs,
                    hadFailure: latestHTTPFailure,
                    failureText: latestHTTPFailure ? failureText : nil),
                Contribution(
                    label: targetHealth.target.name,
                    metric: .reliability,
                    value: hasReliabilityEvidence ? targetHealth.successRate * 100 : nil,
                    hadFailure: latestHTTPFailure || latestDNSFailure,
                    failureText: (latestHTTPFailure || latestDNSFailure) ? failureText : nil)
            ]
        }
    }

    private func buckets(
        for window: HistoryWindow,
        startDate: Date,
        endDate: Date,
        samples: [Sample]) -> [Bucket]
    {
        let count = Self.bucketCount(for: window)
        let totalDuration = max(endDate.timeIntervalSince(startDate), 0.001)
        var bucketSamples = Array(repeating: [Sample](), count: count)

        for sample in samples {
            let index = Self.bucketIndex(
                for: sample.date,
                startDate: startDate,
                endDate: endDate,
                bucketCount: count)
            bucketSamples[index].append(sample)
        }

        return (0 ..< count).map { index in
            let bucketStart = startDate.addingTimeInterval(totalDuration * Double(index) / Double(count))
            let bucketEnd = index == count - 1
                ? endDate
                : startDate.addingTimeInterval(totalDuration * Double(index + 1) / Double(count))
            return Bucket(startDate: bucketStart, endDate: bucketEnd, samples: bucketSamples[index])
        }
    }

    private func bucketedSegments(
        for layer: HealthLayer,
        buckets: [Bucket],
        priorSample: Sample?) -> [LayerTimelineSegment]
    {
        guard !buckets.isEmpty else { return [] }

        var currentStatus = priorSample?.status(for: layer) ?? .pending
        let segments = buckets.map { bucket -> LayerTimelineSegment in
            if let latestSample = bucket.samples.last {
                currentStatus = latestSample.status(for: layer)
            }
            return LayerTimelineSegment(
                startDate: bucket.startDate,
                endDate: bucket.endDate,
                status: currentStatus)
        }

        return Self.mergeAdjacent(segments)
    }

    private func metricTimeline(for metric: HistoryMetric, buckets: [Bucket]) -> MetricTimeline {
        let points = buckets.map { bucket in
            let value = median(of: bucket.samples.compactMap { $0.value(for: metric) })
            return MetricPoint(
                date: bucket.endDate,
                value: value,
                qualityBand: HistoryMetricRules.qualityBand(for: metric, value: value),
                hadFailure: bucket.samples.contains(where: \.hadFailure))
        }
        let values = points.compactMap(\.value)
        return MetricTimeline(
            metric: metric,
            points: points,
            latestValue: points.last(where: { $0.value != nil })?.value,
            medianValue: median(of: values),
            unitText: metric.unitText)
    }

    private func metricBreakdown(for metric: HistoryMetric, buckets: [Bucket]) -> MetricBreakdown {
        let labels = contributionLabels(for: metric, samples: buckets.flatMap(\.samples))
        let series = labels.map { label in
            breakdownSeries(for: label, metric: metric, buckets: buckets)
        }
        let bucketDetails = buckets.map { bucket in
            bucketDetail(for: metric, bucket: bucket)
        }
        return MetricBreakdown(metric: metric, series: series, bucketDetails: bucketDetails)
    }

    private func contributionLabels(for metric: HistoryMetric, samples: [Sample]) -> [String] {
        var seen: Set<String> = []
        var ordered: [String] = []
        for sample in samples {
            for contribution in sample.contributions(for: metric) where seen.insert(contribution.label).inserted {
                ordered.append(contribution.label)
            }
        }
        return ordered
    }

    private func breakdownSeries(
        for label: String,
        metric: HistoryMetric,
        buckets: [Bucket]) -> MetricBreakdownSeries
    {
        let points = buckets.map { bucket in
            let contributions = bucket.samples.compactMap { sample in
                sample.contributions(for: metric).first(where: { $0.label == label })
            }
            let value = median(of: contributions.compactMap(\.value))
            return MetricPoint(
                date: bucket.endDate,
                value: value,
                qualityBand: HistoryMetricRules.qualityBand(for: metric, value: value),
                hadFailure: contributions.contains(where: \.hadFailure))
        }

        return MetricBreakdownSeries(
            label: label,
            points: points,
            latestValue: points.last(where: { $0.value != nil })?.value,
            unitText: metric.unitText)
    }

    private func bucketDetail(for metric: HistoryMetric, bucket: Bucket) -> MetricBucketDetail {
        let labels = contributionLabels(for: metric, samples: bucket.samples)
        let contributions = labels.map { label in
            bucketContribution(for: label, metric: metric, samples: bucket.samples)
        }
        let aggregateValue = median(of: bucket.samples.compactMap { $0.value(for: metric) })
        return MetricBucketDetail(
            metric: metric,
            date: bucket.endDate,
            aggregateValue: aggregateValue,
            unitText: metric.unitText,
            contributions: contributions)
    }

    private func bucketContribution(
        for label: String,
        metric: HistoryMetric,
        samples: [Sample]) -> MetricBucketContribution
    {
        let contributions = samples.compactMap { sample in
            sample.contributions(for: metric).first(where: { $0.label == label })
        }
        let value = median(of: contributions.compactMap(\.value))
        let hadFailure = contributions.contains(where: \.hadFailure)
        let failureText = contributions.compactMap(\.failureText).last
        return MetricBucketContribution(
            label: label,
            value: value,
            unitText: metric.unitText,
            qualityBand: HistoryMetricRules.qualityBand(for: metric, value: value),
            hadFailure: hadFailure,
            failureText: hadFailure ? failureText : nil)
    }

    private static func bucketCount(for window: HistoryWindow) -> Int {
        switch window {
        case .oneMinute:
            12
        case .fiveMinutes:
            20
        case .fifteenMinutes:
            30
        case .sixtyMinutes:
            30
        }
    }

    private static func bucketIndex(
        for date: Date,
        startDate: Date,
        endDate: Date,
        bucketCount: Int) -> Int
    {
        guard bucketCount > 1 else { return 0 }
        let totalDuration = max(endDate.timeIntervalSince(startDate), 0.001)
        let clamped = min(max(date.timeIntervalSince(startDate), 0), totalDuration)
        if clamped >= totalDuration {
            return bucketCount - 1
        }
        let ratio = clamped / totalDuration
        return min(bucketCount - 1, max(0, Int(floor(ratio * Double(bucketCount)))))
    }

    private static func mergeAdjacent(_ segments: [LayerTimelineSegment]) -> [LayerTimelineSegment] {
        guard var current = segments.first else { return [] }
        var merged: [LayerTimelineSegment] = []

        for segment in segments.dropFirst() {
            if segment.status == current.status,
               abs(segment.startDate.timeIntervalSince(current.endDate)) < 0.001
            {
                current = LayerTimelineSegment(
                    startDate: current.startDate,
                    endDate: segment.endDate,
                    status: current.status)
            } else {
                merged.append(current)
                current = segment
            }
        }

        merged.append(current)
        return merged
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
}
