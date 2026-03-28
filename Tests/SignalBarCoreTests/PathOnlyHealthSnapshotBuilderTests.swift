@testable import SignalBarCore
import XCTest

final class PathOnlyHealthSnapshotBuilderTests: XCTestCase {
    func test_initialSnapshotMarksAllLayersPending() {
        let snapshot = PathOnlyHealthSnapshotBuilder.makeInitialSnapshot(at: Date(timeIntervalSince1970: 1))

        XCTAssertEqual(snapshot.diagnosis.title, "Starting")
        XCTAssertEqual(snapshot.layers.map(\.status), [.pending, .pending, .pending, .pending])
    }

    func test_satisfiedPathMarksLinkHealthyAndRemainingLayersPending() {
        let path = PathSnapshot(
            observedAt: Date(timeIntervalSince1970: 2),
            status: .satisfied,
            interface: .wifi,
            isConstrained: false,
            isExpensive: false,
            supportsDNS: true,
            supportsIPv4: true,
            supportsIPv6: true)

        let snapshot = PathOnlyHealthSnapshotBuilder.makeSnapshot(path: path)

        XCTAssertEqual(snapshot.diagnosis.title, "Path connected")
        XCTAssertEqual(snapshot.layers.map(\.status), [.healthy, .pending, .pending, .pending])
        XCTAssertEqual(snapshot.layers.first?.primaryMetricText, "Wi-Fi")
    }

    func test_unsatisfiedPathMarksLinkFailedAndRemainingLayersUnavailable() {
        let path = PathSnapshot(
            observedAt: Date(timeIntervalSince1970: 3),
            status: .unsatisfied,
            interface: nil,
            isConstrained: false,
            isExpensive: false,
            supportsDNS: false,
            supportsIPv4: false,
            supportsIPv6: false)

        let snapshot = PathOnlyHealthSnapshotBuilder.makeSnapshot(path: path)

        XCTAssertEqual(snapshot.diagnosis.title, "Offline")
        XCTAssertEqual(snapshot.layers.map(\.status), [.failed, .unavailable, .unavailable, .unavailable])
    }
}
