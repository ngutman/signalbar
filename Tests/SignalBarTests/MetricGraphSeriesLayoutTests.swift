import Foundation
@testable import SignalBar
import SignalBarCore
import XCTest

final class MetricGraphSeriesLayoutTests: XCTestCase {
    func test_connectedPairsSkipEmptyBucketsButConnectVisibleSamples() {
        let base = Date(timeIntervalSince1970: 1000)
        let points: [MetricPoint] = [
            .init(date: base, value: nil, qualityBand: .unavailable, hadFailure: false),
            .init(date: base.addingTimeInterval(5), value: 20, qualityBand: .okay, hadFailure: false),
            .init(date: base.addingTimeInterval(10), value: nil, qualityBand: .unavailable, hadFailure: false),
            .init(date: base.addingTimeInterval(15), value: nil, qualityBand: .unavailable, hadFailure: false),
            .init(date: base.addingTimeInterval(20), value: 22, qualityBand: .okay, hadFailure: false)
        ]

        let pairs = MetricGraphSeriesLayout.connectedPairs(from: points)

        XCTAssertEqual(pairs.count, 1)
        XCTAssertEqual(pairs[0].0.value, 20)
        XCTAssertEqual(pairs[0].1.value, 22)
    }

    func test_visiblePointsExcludeEmptyBuckets() {
        let base = Date(timeIntervalSince1970: 1000)
        let points: [MetricPoint] = [
            .init(date: base, value: nil, qualityBand: .unavailable, hadFailure: false),
            .init(date: base.addingTimeInterval(5), value: 73, qualityBand: .okay, hadFailure: false),
            .init(date: base.addingTimeInterval(10), value: nil, qualityBand: .unavailable, hadFailure: false),
            .init(date: base.addingTimeInterval(15), value: 50, qualityBand: .good, hadFailure: false)
        ]

        let visible = MetricGraphSeriesLayout.visiblePoints(from: points)

        XCTAssertEqual(visible.map(\.value), [73, 50])
    }
}
