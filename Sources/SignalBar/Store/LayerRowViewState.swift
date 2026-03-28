import Foundation
import SignalBarCore

struct LayerRowViewState: Sendable, Equatable, Identifiable {
    let layer: HealthLayer
    let status: LayerStatus
    let metricText: String
    let detailText: String

    var id: HealthLayer {
        layer
    }
}

enum TargetRowTone: Sendable, Equatable {
    case healthy
    case degraded
    case failed
    case pending
}

struct TargetRowViewState: Sendable, Equatable, Identifiable {
    let id: UUID
    let labelText: String
    let statusText: String
    let detailText: String?
    let tone: TargetRowTone
}

struct StatusPresentation: Sendable, Equatable {
    let titleText: String
    let summaryText: String
    let contextText: String
    let layerRows: [LayerRowViewState]
    let targetRows: [TargetRowViewState]
    let watchedTargetRow: TargetRowViewState?
}
