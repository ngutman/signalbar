import Foundation

struct ProbeScheduler {
    enum SweepKind {
        case dns
        case http
    }

    private struct ScheduledTarget {
        let schedule: EffectiveProbeSchedule
        var dueDate: Date
    }

    private let cadenceResolver = ProbeCadenceResolver()
    private var cadenceConfiguration = ProbeCadenceConfiguration()
    private var dnsScheduledTargets: [UUID: ScheduledTarget] = [:]
    private var httpScheduledTargets: [UUID: ScheduledTarget] = [:]

    mutating func updateCadenceConfiguration(
        _ configuration: ProbeCadenceConfiguration,
        among targets: [ProbeTarget],
        now: Date)
    {
        cadenceConfiguration = configuration

        if !dnsScheduledTargets.isEmpty {
            dnsScheduledTargets = makeScheduledTargets(for: targets, anchoredAt: now, startNextCycle: false)
        }
        if !httpScheduledTargets.isEmpty {
            httpScheduledTargets = makeScheduledTargets(for: targets, anchoredAt: now, startNextCycle: false)
        }
    }

    mutating func nextDueDate(for kind: SweepKind, among targets: [ProbeTarget], now: Date) -> Date? {
        reconcileTargets(targets, for: kind, now: now)
        return scheduledTargets(for: kind).values.map(\.dueDate).min()
    }

    mutating func dueTargets(for kind: SweepKind, among targets: [ProbeTarget], now: Date) -> [ProbeTarget] {
        reconcileTargets(targets, for: kind, now: now)
        let scheduledTargets = scheduledTargets(for: kind)
        return targets.filter { target in
            guard let dueDate = scheduledTargets[target.id]?.dueDate else { return false }
            return dueDate <= now
        }
    }

    mutating func markCompleted(_ targets: [ProbeTarget], for kind: SweepKind, completedAt: Date) {
        guard !targets.isEmpty else { return }

        var scheduledTargets = scheduledTargets(for: kind)
        for target in targets {
            guard var scheduledTarget = scheduledTargets[target.id] else { continue }
            var nextDueDate = scheduledTarget.dueDate
            repeat {
                nextDueDate = nextDueDate.addingTimeInterval(scheduledTarget.schedule.interval)
            } while nextDueDate <= completedAt
            scheduledTarget.dueDate = nextDueDate
            scheduledTargets[target.id] = scheduledTarget
        }
        setScheduledTargets(scheduledTargets, for: kind)
    }

    mutating func markFullSweepCompleted(_ targets: [ProbeTarget], for kind: SweepKind, completedAt: Date) {
        guard !targets.isEmpty else { return }

        var scheduledTargets = scheduledTargets(for: kind)
        let rescheduledTargets = makeScheduledTargets(for: targets, anchoredAt: completedAt, startNextCycle: true)
        for target in targets {
            if let scheduledTarget = rescheduledTargets[target.id] {
                scheduledTargets[target.id] = scheduledTarget
            }
        }
        setScheduledTargets(scheduledTargets, for: kind)
    }

    mutating func reset() {
        dnsScheduledTargets.removeAll()
        httpScheduledTargets.removeAll()
    }

    private mutating func reconcileTargets(_ targets: [ProbeTarget], for kind: SweepKind, now: Date) {
        let activeTargetIDs = Set(targets.map(\.id))
        var scheduledTargets = scheduledTargets(for: kind)
        scheduledTargets = scheduledTargets.filter { activeTargetIDs.contains($0.key) }

        for target in targets {
            let schedule = cadenceResolver.schedule(
                for: target,
                among: targets,
                configuration: cadenceConfiguration)

            if let existing = scheduledTargets[target.id], existing.schedule == schedule {
                continue
            }

            scheduledTargets[target.id] = ScheduledTarget(
                schedule: schedule,
                dueDate: now.addingTimeInterval(schedule.initialOffset))
        }

        setScheduledTargets(scheduledTargets, for: kind)
    }

    private func makeScheduledTargets(
        for targets: [ProbeTarget],
        anchoredAt anchorDate: Date,
        startNextCycle: Bool)
        -> [UUID: ScheduledTarget]
    {
        Dictionary(uniqueKeysWithValues: targets.map { target in
            let schedule = cadenceResolver.schedule(
                for: target,
                among: targets,
                configuration: cadenceConfiguration)
            let cycleOffset = startNextCycle ? schedule.interval : 0
            return (
                target.id,
                ScheduledTarget(
                    schedule: schedule,
                    dueDate: anchorDate.addingTimeInterval(schedule.initialOffset + cycleOffset)))
        })
    }

    private func scheduledTargets(for kind: SweepKind) -> [UUID: ScheduledTarget] {
        switch kind {
        case .dns:
            dnsScheduledTargets
        case .http:
            httpScheduledTargets
        }
    }

    private mutating func setScheduledTargets(_ scheduledTargets: [UUID: ScheduledTarget], for kind: SweepKind) {
        switch kind {
        case .dns:
            dnsScheduledTargets = scheduledTargets
        case .http:
            httpScheduledTargets = scheduledTargets
        }
    }
}
