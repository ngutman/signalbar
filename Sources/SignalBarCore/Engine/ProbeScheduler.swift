import Foundation

struct ProbeScheduler {
    enum SweepKind {
        case dns
        case http
    }

    private var dnsDueDates: [UUID: Date] = [:]
    private var httpDueDates: [UUID: Date] = [:]

    mutating func dueTargets(for kind: SweepKind, among targets: [ProbeTarget], now: Date) -> [ProbeTarget] {
        reconcileTargets(targets, for: kind, now: now)
        let dueDates = dueDates(for: kind)
        return targets.filter { target in
            guard let dueDate = dueDates[target.id] else { return false }
            return dueDate <= now
        }
    }

    mutating func markCompleted(_ targets: [ProbeTarget], for kind: SweepKind, completedAt: Date) {
        guard !targets.isEmpty else { return }
        var dueDates = dueDates(for: kind)
        for target in targets {
            dueDates[target.id] = completedAt.addingTimeInterval(target.interval)
        }
        setDueDates(dueDates, for: kind)
    }

    mutating func reset() {
        dnsDueDates.removeAll()
        httpDueDates.removeAll()
    }

    private mutating func reconcileTargets(_ targets: [ProbeTarget], for kind: SweepKind, now: Date) {
        let activeTargetIDs = Set(targets.map(\.id))
        var dueDates = dueDates(for: kind)
        dueDates = dueDates.filter { activeTargetIDs.contains($0.key) }
        for target in targets where dueDates[target.id] == nil {
            dueDates[target.id] = now
        }
        setDueDates(dueDates, for: kind)
    }

    private func dueDates(for kind: SweepKind) -> [UUID: Date] {
        switch kind {
        case .dns:
            dnsDueDates
        case .http:
            httpDueDates
        }
    }

    private mutating func setDueDates(_ dueDates: [UUID: Date], for kind: SweepKind) {
        switch kind {
        case .dns:
            dnsDueDates = dueDates
        case .http:
            httpDueDates = dueDates
        }
    }
}
