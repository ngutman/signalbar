import Foundation

enum SnapshotStatistics {
    static func successRate(for results: [DNSProbeResult]) -> Double {
        guard !results.isEmpty else { return 0 }
        let successCount = results.filter(\.success).count
        return Double(successCount) / Double(results.count)
    }

    static func successRate(for results: [HTTPProbeResult]) -> Double {
        guard !results.isEmpty else { return 0 }
        let successCount = results.filter(\.success).count
        return Double(successCount) / Double(results.count)
    }

    static func median(of values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let middleIndex = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[middleIndex - 1] + sorted[middleIndex]) / 2
        }
        return sorted[middleIndex]
    }

    static func jitter(of results: [HTTPProbeResult]) -> Double? {
        let orderedValues = results
            .sorted { $0.startedAt < $1.startedAt }
            .compactMap(\.totalMs)
        guard orderedValues.count >= 2 else { return nil }
        let deltas = zip(orderedValues, orderedValues.dropFirst()).map { abs($1 - $0) }
        return deltas.reduce(0, +) / Double(deltas.count)
    }

    static func overallScore(for layers: [LayerHealthSnapshot]) -> Double {
        guard !layers.isEmpty else { return 0 }
        let score = layers.reduce(0.0) { partialResult, layer in
            partialResult + layer.score
        }
        return score / Double(layers.count)
    }
}
