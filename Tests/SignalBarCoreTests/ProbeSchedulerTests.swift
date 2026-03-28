import Foundation
@testable import SignalBarCore
import XCTest

final class ProbeSchedulerTests: XCTestCase {
    func test_initialTargetsAreImmediatelyDue() {
        var scheduler = ProbeScheduler()
        let now = Date(timeIntervalSince1970: 1000)
        let targets = [
            target(name: "Fast", interval: 15),
            target(name: "Slow", interval: 30)
        ]

        let dueTargets = scheduler.dueTargets(for: .dns, among: targets, now: now)

        XCTAssertEqual(Set(dueTargets.map(\.id)), Set(targets.map(\.id)))
    }

    func test_completedTargetsRespectPerTargetIntervals() {
        var scheduler = ProbeScheduler()
        let now = Date(timeIntervalSince1970: 1000)
        let fastTarget = target(name: "Fast", interval: 15)
        let slowTarget = target(name: "Slow", interval: 30)
        let targets = [fastTarget, slowTarget]

        _ = scheduler.dueTargets(for: .http, among: targets, now: now)
        scheduler.markCompleted(targets, for: .http, completedAt: now)

        XCTAssertTrue(scheduler.dueTargets(for: .http, among: targets, now: now.addingTimeInterval(10)).isEmpty)
        XCTAssertEqual(
            scheduler.dueTargets(for: .http, among: targets, now: now.addingTimeInterval(20)).map(\.id),
            [fastTarget.id])
        XCTAssertEqual(
            Set(scheduler.dueTargets(for: .http, among: targets, now: now.addingTimeInterval(31)).map(\.id)),
            Set(targets.map(\.id)))
    }

    func test_removedTargetsArePrunedAndNewTargetsStartDueImmediately() {
        var scheduler = ProbeScheduler()
        let now = Date(timeIntervalSince1970: 1000)
        let originalTarget = target(name: "Original", interval: 15)
        let removedTarget = target(name: "Removed", interval: 15)
        let newTarget = target(name: "New", interval: 15)

        _ = scheduler.dueTargets(for: .dns, among: [originalTarget, removedTarget], now: now)
        scheduler.markCompleted([originalTarget, removedTarget], for: .dns, completedAt: now)

        let dueTargets = scheduler.dueTargets(
            for: .dns,
            among: [originalTarget, newTarget],
            now: now.addingTimeInterval(5))

        XCTAssertEqual(dueTargets.map(\.id), [newTarget.id])
    }

    private func target(name: String, interval: TimeInterval) -> ProbeTarget {
        ProbeTarget(
            kind: .control,
            name: name,
            url: URL(string: "https://example.com/\(name.lowercased())")!,
            method: .head,
            interval: interval,
            timeout: 2.5)
    }
}
