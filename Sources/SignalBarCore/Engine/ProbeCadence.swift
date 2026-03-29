import Foundation

public enum RefreshCadenceProfile: String, CaseIterable, Codable, Sendable {
    case powerSaver
    case balanced
    case responsive
    case custom

    public static let customIntervalRange = 5 ... 300
    public static let defaultCustomIntervalSeconds = 15

    public static var defaultValue: RefreshCadenceProfile {
        .balanced
    }
}

public struct ProbeCadenceConfiguration: Sendable, Equatable {
    public var profile: RefreshCadenceProfile
    public var customIntervalSeconds: Int
    public var lowPowerModeBackoffEnabled: Bool

    public init(
        profile: RefreshCadenceProfile = .defaultValue,
        customIntervalSeconds: Int = RefreshCadenceProfile.defaultCustomIntervalSeconds,
        lowPowerModeBackoffEnabled: Bool = true)
    {
        self.profile = profile
        self.customIntervalSeconds = ProbeCadenceConfiguration.clampCustomIntervalSeconds(customIntervalSeconds)
        self.lowPowerModeBackoffEnabled = lowPowerModeBackoffEnabled
    }

    public var resolvedCustomIntervalSeconds: Int {
        Self.clampCustomIntervalSeconds(customIntervalSeconds)
    }

    public static func clampCustomIntervalSeconds(_ customIntervalSeconds: Int) -> Int {
        min(max(customIntervalSeconds, RefreshCadenceProfile.customIntervalRange.lowerBound), RefreshCadenceProfile.customIntervalRange.upperBound)
    }
}

struct EffectiveProbeSchedule: Sendable, Equatable {
    let interval: TimeInterval
    let initialOffset: TimeInterval
}

struct ProbeCadenceResolver {
    func schedule(
        for target: ProbeTarget,
        among activeTargets: [ProbeTarget],
        configuration: ProbeCadenceConfiguration)
        -> EffectiveProbeSchedule
    {
        let interval = interval(for: target, configuration: configuration)

        switch target.kind {
        case .control:
            let controlTargets = activeTargets.filter { $0.kind == .control }
            let controlCount = max(controlTargets.count, 1)
            let targetIndex = controlTargets.firstIndex { $0.id == target.id } ?? 0
            return EffectiveProbeSchedule(
                interval: interval,
                initialOffset: interval * Double(targetIndex) / Double(controlCount))

        case .custom, .watched:
            let controlCount = max(activeTargets.filter { $0.kind == .control }.count, 1)
            return EffectiveProbeSchedule(
                interval: interval,
                initialOffset: interval / Double(controlCount * 2))
        }
    }

    private func interval(for target: ProbeTarget, configuration: ProbeCadenceConfiguration) -> TimeInterval {
        switch target.kind {
        case .control, .watched:
            switch configuration.profile {
            case .powerSaver:
                30
            case .balanced:
                15
            case .responsive:
                10
            case .custom:
                TimeInterval(configuration.resolvedCustomIntervalSeconds)
            }

        case .custom:
            target.interval
        }
    }
}
