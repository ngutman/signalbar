import Foundation

public enum HistoryWindow: String, Sendable, Codable, CaseIterable {
    case oneMinute
    case fiveMinutes
    case fifteenMinutes
    case sixtyMinutes

    public var duration: TimeInterval {
        switch self {
        case .oneMinute:
            60
        case .fiveMinutes:
            5 * 60
        case .fifteenMinutes:
            15 * 60
        case .sixtyMinutes:
            60 * 60
        }
    }

    public var displayName: String {
        switch self {
        case .oneMinute:
            "1m"
        case .fiveMinutes:
            "5m"
        case .fifteenMinutes:
            "15m"
        case .sixtyMinutes:
            "60m"
        }
    }

    public static var defaultValue: HistoryWindow {
        .oneMinute
    }
}

public enum HistoryMetric: String, Sendable, Codable, CaseIterable {
    case ping
    case jitter
    case reliability
    case overview

    public var displayName: String {
        switch self {
        case .ping:
            "Ping"
        case .jitter:
            "Jitter"
        case .reliability:
            "Reliability"
        case .overview:
            "Overview"
        }
    }

    public var unitText: String {
        switch self {
        case .ping, .jitter:
            "ms"
        case .reliability:
            "%"
        case .overview:
            ""
        }
    }

    public static var defaultValue: HistoryMetric {
        .ping
    }
}

public enum MetricQualityBand: String, Sendable, Codable, Equatable, CaseIterable {
    case good
    case okay
    case degraded
    case bad
    case unavailable
}

public struct MetricPoint: Sendable, Codable, Equatable, Identifiable {
    public let date: Date
    public let value: Double?
    public let qualityBand: MetricQualityBand
    public let hadFailure: Bool

    public init(date: Date, value: Double?, qualityBand: MetricQualityBand, hadFailure: Bool) {
        self.date = date
        self.value = value
        self.qualityBand = qualityBand
        self.hadFailure = hadFailure
    }

    public var id: Double {
        date.timeIntervalSinceReferenceDate
    }
}

public struct MetricTimeline: Sendable, Codable, Equatable {
    public let metric: HistoryMetric
    public let points: [MetricPoint]
    public let latestValue: Double?
    public let medianValue: Double?
    public let unitText: String

    public init(
        metric: HistoryMetric,
        points: [MetricPoint],
        latestValue: Double?,
        medianValue: Double?,
        unitText: String)
    {
        self.metric = metric
        self.points = points
        self.latestValue = latestValue
        self.medianValue = medianValue
        self.unitText = unitText
    }
}

public struct LayerTimelineSegment: Sendable, Codable, Equatable, Identifiable {
    public let startDate: Date
    public let endDate: Date
    public let status: LayerStatus

    public init(startDate: Date, endDate: Date, status: LayerStatus) {
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
    }

    public var id: String {
        "\(startDate.timeIntervalSinceReferenceDate)-\(endDate.timeIntervalSinceReferenceDate)-\(status.rawValue)"
    }
}

public struct LayerTimeline: Sendable, Codable, Equatable, Identifiable {
    public let layer: HealthLayer
    public let segments: [LayerTimelineSegment]

    public init(layer: HealthLayer, segments: [LayerTimelineSegment]) {
        self.layer = layer
        self.segments = segments
    }

    public var id: HealthLayer {
        layer
    }
}

public struct MetricBreakdownSeries: Sendable, Codable, Equatable, Identifiable {
    public let label: String
    public let points: [MetricPoint]
    public let latestValue: Double?
    public let unitText: String

    public init(label: String, points: [MetricPoint], latestValue: Double?, unitText: String) {
        self.label = label
        self.points = points
        self.latestValue = latestValue
        self.unitText = unitText
    }

    public var id: String {
        label
    }
}

public struct MetricBucketContribution: Sendable, Codable, Equatable, Identifiable {
    public let label: String
    public let value: Double?
    public let unitText: String
    public let qualityBand: MetricQualityBand
    public let hadFailure: Bool
    public let failureText: String?

    public init(
        label: String,
        value: Double?,
        unitText: String,
        qualityBand: MetricQualityBand,
        hadFailure: Bool,
        failureText: String?)
    {
        self.label = label
        self.value = value
        self.unitText = unitText
        self.qualityBand = qualityBand
        self.hadFailure = hadFailure
        self.failureText = failureText
    }

    public var id: String {
        label
    }
}

public struct MetricBucketDetail: Sendable, Codable, Equatable, Identifiable {
    public let metric: HistoryMetric
    public let date: Date
    public let aggregateValue: Double?
    public let unitText: String
    public let contributions: [MetricBucketContribution]

    public init(
        metric: HistoryMetric,
        date: Date,
        aggregateValue: Double?,
        unitText: String,
        contributions: [MetricBucketContribution])
    {
        self.metric = metric
        self.date = date
        self.aggregateValue = aggregateValue
        self.unitText = unitText
        self.contributions = contributions
    }

    public var id: String {
        "\(metric.rawValue)-\(date.timeIntervalSinceReferenceDate)"
    }
}

public struct MetricBreakdown: Sendable, Codable, Equatable, Identifiable {
    public let metric: HistoryMetric
    public let series: [MetricBreakdownSeries]
    public let bucketDetails: [MetricBucketDetail]

    public init(metric: HistoryMetric, series: [MetricBreakdownSeries], bucketDetails: [MetricBucketDetail]) {
        self.metric = metric
        self.series = series
        self.bucketDetails = bucketDetails
    }

    public var id: HistoryMetric {
        metric
    }
}

public struct HistorySnapshot: Sendable, Codable, Equatable {
    public let generatedAt: Date
    public let window: HistoryWindow
    public let startDate: Date
    public let endDate: Date
    public let layerTimelines: [LayerTimeline]
    public let pingTimeline: MetricTimeline?
    public let jitterTimeline: MetricTimeline?
    public let reliabilityTimeline: MetricTimeline?
    public let metricBreakdowns: [MetricBreakdown]

    public init(
        generatedAt: Date,
        window: HistoryWindow,
        startDate: Date,
        endDate: Date,
        layerTimelines: [LayerTimeline],
        pingTimeline: MetricTimeline?,
        jitterTimeline: MetricTimeline?,
        reliabilityTimeline: MetricTimeline?,
        metricBreakdowns: [MetricBreakdown] = [])
    {
        self.generatedAt = generatedAt
        self.window = window
        self.startDate = startDate
        self.endDate = endDate
        self.layerTimelines = layerTimelines
        self.pingTimeline = pingTimeline
        self.jitterTimeline = jitterTimeline
        self.reliabilityTimeline = reliabilityTimeline
        self.metricBreakdowns = metricBreakdowns
    }

    public func timeline(for metric: HistoryMetric) -> MetricTimeline? {
        switch metric {
        case .ping:
            pingTimeline
        case .jitter:
            jitterTimeline
        case .reliability:
            reliabilityTimeline
        case .overview:
            nil
        }
    }

    public func breakdown(for metric: HistoryMetric) -> MetricBreakdown? {
        metricBreakdowns.first(where: { $0.metric == metric })
    }
}

public extension HistorySnapshot {
    static func placeholder(window: HistoryWindow, at date: Date = .now) -> HistorySnapshot {
        let startDate = date.addingTimeInterval(-window.duration)
        let pendingSegments = [LayerTimelineSegment(startDate: startDate, endDate: date, status: .pending)]
        let unavailablePoints = [
            MetricPoint(date: startDate, value: nil, qualityBand: .unavailable, hadFailure: false),
            MetricPoint(date: date, value: nil, qualityBand: .unavailable, hadFailure: false)
        ]
        return HistorySnapshot(
            generatedAt: date,
            window: window,
            startDate: startDate,
            endDate: date,
            layerTimelines: HealthLayer.allCases.map { layer in
                LayerTimeline(layer: layer, segments: pendingSegments)
            },
            pingTimeline: MetricTimeline(
                metric: .ping,
                points: unavailablePoints,
                latestValue: nil,
                medianValue: nil,
                unitText: HistoryMetric.ping.unitText),
            jitterTimeline: MetricTimeline(
                metric: .jitter,
                points: unavailablePoints,
                latestValue: nil,
                medianValue: nil,
                unitText: HistoryMetric.jitter.unitText),
            reliabilityTimeline: MetricTimeline(
                metric: .reliability,
                points: unavailablePoints,
                latestValue: nil,
                medianValue: nil,
                unitText: HistoryMetric.reliability.unitText),
            metricBreakdowns: [
                MetricBreakdown(metric: .ping, series: [], bucketDetails: []),
                MetricBreakdown(metric: .jitter, series: [], bucketDetails: []),
                MetricBreakdown(metric: .reliability, series: [], bucketDetails: [])
            ])
    }
}
