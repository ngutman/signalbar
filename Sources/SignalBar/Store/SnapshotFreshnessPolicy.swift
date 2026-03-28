import Foundation
import SignalBarCore

struct SnapshotFreshnessPolicy {
    var staleThreshold: TimeInterval = 30

    func applying(to snapshot: HealthSnapshot?, isPaused: Bool, now: Date) -> HealthSnapshot? {
        guard let snapshot else { return nil }
        let isStale = snapshot.isStale || isStale(snapshot: snapshot, isPaused: isPaused, now: now)
        guard snapshot.isStale != isStale else { return snapshot }
        return snapshot.withStaleState(isStale)
    }

    func isStale(snapshot: HealthSnapshot?, isPaused: Bool, now: Date) -> Bool {
        guard let snapshot else { return false }
        if isPaused {
            return true
        }
        guard snapshot.path?.status == .satisfied else {
            return false
        }
        return now.timeIntervalSince(snapshot.generatedAt) >= staleThreshold
    }
}

private extension HealthSnapshot {
    func withStaleState(_ isStale: Bool) -> HealthSnapshot {
        HealthSnapshot(
            generatedAt: generatedAt,
            path: path,
            layers: layers,
            controlTargets: controlTargets,
            watchedTarget: watchedTarget,
            diagnosis: diagnosis,
            isStale: isStale,
            overallScore: overallScore,
            medianLatencyMs: medianLatencyMs,
            jitterMs: jitterMs,
            reliability: reliability)
    }
}
