import Foundation
@testable import SignalBarCore
import XCTest

final class ProbeCadenceResolverTests: XCTestCase {
    func test_balancedControlTargetsUseExpectedIntervalsAndOffsets() {
        let resolver = ProbeCadenceResolver()
        let targets = ProbeTarget.defaultControlTargets
        let configuration = ProbeCadenceConfiguration(profile: .balanced)

        let appleSchedule = resolver.schedule(for: targets[0], among: targets, configuration: configuration)
        let cloudflareSchedule = resolver.schedule(for: targets[1], among: targets, configuration: configuration)
        let googleSchedule = resolver.schedule(for: targets[2], among: targets, configuration: configuration)

        XCTAssertEqual(appleSchedule.interval, 15)
        XCTAssertEqual(cloudflareSchedule.interval, 15)
        XCTAssertEqual(googleSchedule.interval, 15)
        XCTAssertEqual(appleSchedule.initialOffset, 0)
        XCTAssertEqual(cloudflareSchedule.initialOffset, 5)
        XCTAssertEqual(googleSchedule.initialOffset, 10)
    }

    func test_responsiveControlTargetsSpreadAcrossShorterInterval() {
        let resolver = ProbeCadenceResolver()
        let targets = ProbeTarget.defaultControlTargets
        let configuration = ProbeCadenceConfiguration(profile: .responsive)

        let cloudflareSchedule = resolver.schedule(for: targets[1], among: targets, configuration: configuration)
        let googleSchedule = resolver.schedule(for: targets[2], among: targets, configuration: configuration)

        XCTAssertEqual(cloudflareSchedule.interval, 10)
        XCTAssertEqual(googleSchedule.interval, 10)
        XCTAssertEqual(cloudflareSchedule.initialOffset, 10.0 / 3.0, accuracy: 0.0001)
        XCTAssertEqual(googleSchedule.initialOffset, 20.0 / 3.0, accuracy: 0.0001)
    }

    func test_watchedTargetUsesProfileIntervalAndMidSlotOffset() {
        let resolver = ProbeCadenceResolver()
        let watchedTarget = ProbeTarget(
            kind: .watched,
            name: "GitHub",
            url: URL(string: "https://github.com")!,
            method: .auto,
            interval: 15,
            timeout: 3.0)
        let targets = ProbeTarget.defaultControlTargets + [watchedTarget]
        let configuration = ProbeCadenceConfiguration(profile: .balanced)

        let watchedSchedule = resolver.schedule(for: watchedTarget, among: targets, configuration: configuration)

        XCTAssertEqual(watchedSchedule.interval, 15)
        XCTAssertEqual(watchedSchedule.initialOffset, 2.5)
    }

    func test_customProfileUsesConfiguredIntervalForControlTargets() {
        let resolver = ProbeCadenceResolver()
        let targets = ProbeTarget.defaultControlTargets
        let configuration = ProbeCadenceConfiguration(profile: .custom, customIntervalSeconds: 21)

        let appleSchedule = resolver.schedule(for: targets[0], among: targets, configuration: configuration)
        let googleSchedule = resolver.schedule(for: targets[2], among: targets, configuration: configuration)

        XCTAssertEqual(appleSchedule.interval, 21)
        XCTAssertEqual(googleSchedule.interval, 21)
        XCTAssertEqual(googleSchedule.initialOffset, 14)
    }

    func test_customTargetKeepsStoredInterval() {
        let resolver = ProbeCadenceResolver()
        let customTarget = ProbeTarget(
            kind: .custom,
            name: "Internal",
            url: URL(string: "https://example.com/internal")!,
            method: .auto,
            interval: 42,
            timeout: 3.0)
        let configuration = ProbeCadenceConfiguration(profile: .responsive)

        let schedule = resolver.schedule(for: customTarget, among: [customTarget], configuration: configuration)

        XCTAssertEqual(schedule.interval, 42)
    }
}
