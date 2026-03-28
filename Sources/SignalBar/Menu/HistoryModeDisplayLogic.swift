import SignalBarCore

struct ReliabilityContributionSummary: Equatable {
    let healthyCount: Int
    let degradedCount: Int
    let failingCount: Int
    let unavailableCount: Int

    var totalCount: Int {
        healthyCount + degradedCount + failingCount + unavailableCount
    }

    var hasIssues: Bool {
        degradedCount > 0 || failingCount > 0
    }
}

enum HistoryModeDisplayLogic {
    static func shouldShowTargetsCard(selectedMetric: HistoryMetric, targetCount: Int) -> Bool {
        selectedMetric == .overview && targetCount > 0
    }

    static func reliabilityValueText(_ value: Double?) -> String {
        guard let value else { return "No data" }
        return "\(Int(value.rounded()))% success"
    }

    static func reliabilityContributionSummary(for contributions: [MetricBucketContribution])
        -> ReliabilityContributionSummary
    {
        var healthyCount = 0
        var degradedCount = 0
        var failingCount = 0
        var unavailableCount = 0

        for contribution in contributions {
            if contribution.value == nil, contribution.failureText == nil, contribution.hadFailure == false {
                unavailableCount += 1
                continue
            }

            if contribution.hadFailure || contribution.qualityBand == .bad || (contribution.value ?? 0) <= 0 {
                failingCount += 1
            } else if contribution.qualityBand == .good {
                healthyCount += 1
            } else if contribution.qualityBand == .unavailable {
                unavailableCount += 1
            } else {
                degradedCount += 1
            }
        }

        return ReliabilityContributionSummary(
            healthyCount: healthyCount,
            degradedCount: degradedCount,
            failingCount: failingCount,
            unavailableCount: unavailableCount)
    }

    static func reliabilityIssueContributions(from contributions: [MetricBucketContribution])
        -> [MetricBucketContribution]
    {
        let issues = contributions.filter { contribution in
            contribution.hadFailure || contribution.qualityBand == .bad || contribution
                .qualityBand == .degraded || contribution.qualityBand == .okay
        }
        return issues.sorted { lhs, rhs in
            if lhs.hadFailure != rhs.hadFailure {
                return lhs.hadFailure && !rhs.hadFailure
            }
            return lhs.label < rhs.label
        }
    }
}
