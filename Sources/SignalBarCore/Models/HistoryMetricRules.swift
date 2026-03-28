import Foundation

public enum HistoryMetricRules {
    public static func qualityBand(for metric: HistoryMetric, value: Double?) -> MetricQualityBand {
        guard let value else { return .unavailable }

        switch metric {
        case .ping:
            switch value {
            case ..<60:
                return .good
            case ..<120:
                return .okay
            case ..<250:
                return .degraded
            default:
                return .bad
            }
        case .jitter:
            switch value {
            case ..<15:
                return .good
            case ..<30:
                return .okay
            case ..<60:
                return .degraded
            default:
                return .bad
            }
        case .reliability:
            switch value {
            case let x where x >= 99:
                return .good
            case 95 ..< 99:
                return .okay
            case 80 ..< 95:
                return .degraded
            default:
                return .bad
            }
        case .overview:
            return .unavailable
        }
    }

    public static func upperBound(for metric: HistoryMetric, maxValue: Double) -> Double {
        switch metric {
        case .ping:
            roundUp(max(300, maxValue * 1.15), step: 50)
        case .jitter:
            roundUp(max(80, maxValue * 1.15), step: 10)
        case .reliability:
            100
        case .overview:
            1
        }
    }

    private static func roundUp(_ value: Double, step: Double) -> Double {
        guard step > 0 else { return value }
        return ceil(value / step) * step
    }
}
