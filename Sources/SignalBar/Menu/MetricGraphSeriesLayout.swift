import Foundation
import SignalBarCore

enum MetricGraphSeriesLayout {
    static func visiblePoints(from points: [MetricPoint]) -> [MetricPoint] {
        points.filter { $0.value != nil }
    }

    static func connectedPairs(from points: [MetricPoint]) -> [(MetricPoint, MetricPoint)] {
        let visiblePoints = Self.visiblePoints(from: points)
        guard visiblePoints.count >= 2 else { return [] }
        return Array(zip(visiblePoints, visiblePoints.dropFirst()))
    }
}
