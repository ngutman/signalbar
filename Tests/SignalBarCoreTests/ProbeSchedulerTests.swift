import Foundation
@testable import SignalBarCore
import XCTest

final class ProbeSchedulerTests: XCTestCase {
    func test_initialBalancedScheduleStaggersTargetsAcrossInterval() {
        var scheduler = ProbeScheduler()
        let now = Date(timeIntervalSince1970: 1000)
        let targets = [
            target(name: "Apple", interval: 15),
            target(name: "Cloudflare", interval: 15),
            target(name: "Google", interval: 15)
        ]

        XCTAssertEqual(scheduler.dueTargets(for: .dns, among: targets, now: now).map(\.id), [targets[0].id])

        scheduler.markCompleted([targets[0]], for: .dns, completedAt: now)
        XCTAssertTrue(scheduler.dueTargets(for: .dns, among: targets, now: now.addingTimeInterval(4.9)).isEmpty)
        XCTAssertEqual(
            scheduler.dueTargets(for: .dns, among: targets, now: now.addingTimeInterval(5)).map(\.id),
            [targets[1].id])

        scheduler.markCompleted([targets[1]], for: .dns, completedAt: now.addingTimeInterval(5))
        XCTAssertEqual(
            scheduler.dueTargets(for: .dns, among: targets, now: now.addingTimeInterval(10)).map(\.id),
            [targets[2].id])
    }

    func test_fullSweepCompletionPreservesNextStaggeredCycle() {
        var scheduler = ProbeScheduler()
        let now = Date(timeIntervalSince1970: 1000)
        let targets = [
            target(name: "Apple", interval: 15),
            target(name: "Cloudflare", interval: 15),
            target(name: "Google", interval: 15)
        ]

        scheduler.markFullSweepCompleted(targets, for: .http, completedAt: now)

        XCTAssertTrue(scheduler.dueTargets(for: .http, among: targets, now: now.addingTimeInterval(14.9)).isEmpty)
        XCTAssertEqual(
            scheduler.dueTargets(for: .http, among: targets, now: now.addingTimeInterval(15)).map(\.id),
            [targets[0].id])

        scheduler.markCompleted([targets[0]], for: .http, completedAt: now.addingTimeInterval(15))
        XCTAssertEqual(
            scheduler.dueTargets(for: .http, among: targets, now: now.addingTimeInterval(20)).map(\.id),
            [targets[1].id])

        scheduler.markCompleted([targets[1]], for: .http, completedAt: now.addingTimeInterval(20))
        XCTAssertEqual(
            scheduler.dueTargets(for: .http, among: targets, now: now.addingTimeInterval(25)).map(\.id),
            [targets[2].id])
    }

    func test_updatingCadenceConfigurationReseedsUsingNewProfile() {
        var scheduler = ProbeScheduler()
        let now = Date(timeIntervalSince1970: 1000)
        let target = target(name: "Control", interval: 15)

        _ = scheduler.dueTargets(for: .dns, among: [target], now: now)
        scheduler.markCompleted([target], for: .dns, completedAt: now)
        XCTAssertTrue(scheduler.dueTargets(for: .dns, among: [target], now: now.addingTimeInterval(10)).isEmpty)

        scheduler.updateCadenceConfiguration(
            ProbeCadenceConfiguration(profile: .responsive),
            among: [target],
            now: now.addingTimeInterval(10))

        XCTAssertEqual(
            scheduler.dueTargets(for: .dns, among: [target], now: now.addingTimeInterval(10)).map(\.id),
            [target.id])
    }

    func test_customCadenceConfigurationUsesManualIntervalSpacing() {
        var scheduler = ProbeScheduler()
        let now = Date(timeIntervalSince1970: 1000)
        let targets = [
            target(name: "Apple", interval: 15),
            target(name: "Cloudflare", interval: 15),
            target(name: "Google", interval: 15)
        ]

        scheduler.updateCadenceConfiguration(
            ProbeCadenceConfiguration(profile: .custom, customIntervalSeconds: 21),
            among: targets,
            now: now)

        XCTAssertEqual(scheduler.dueTargets(for: .dns, among: targets, now: now).map(\.id), [targets[0].id])

        scheduler.markCompleted([targets[0]], for: .dns, completedAt: now)
        XCTAssertEqual(
            scheduler.dueTargets(for: .dns, among: targets, now: now.addingTimeInterval(7)).map(\.id),
            [targets[1].id])

        scheduler.markCompleted([targets[1]], for: .dns, completedAt: now.addingTimeInterval(7))
        XCTAssertEqual(
            scheduler.dueTargets(for: .dns, among: targets, now: now.addingTimeInterval(14)).map(\.id),
            [targets[2].id])
    }

    func test_removedTargetsArePrunedAndNewTargetsUseCurrentConfiguration() {
        var scheduler = ProbeScheduler()
        let now = Date(timeIntervalSince1970: 1000)
        let originalTarget = target(name: "Original", interval: 15)
        let removedTarget = target(name: "Removed", interval: 15)
        let newTarget = target(name: "New", interval: 15)

        _ = scheduler.dueTargets(for: .dns, among: [originalTarget, removedTarget], now: now)
        scheduler.markCompleted([originalTarget], for: .dns, completedAt: now)

        XCTAssertTrue(
            scheduler.dueTargets(
                for: .dns,
                among: [originalTarget, newTarget],
                now: now.addingTimeInterval(5))
                .isEmpty)

        let dueTargets = scheduler.dueTargets(
            for: .dns,
            among: [originalTarget, newTarget],
            now: now.addingTimeInterval(12.5))

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
