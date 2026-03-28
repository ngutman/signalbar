import Foundation

public enum DiagnosisLayer: String, Sendable, Codable {
    case link
    case dns
    case internet
    case quality
    case watchedService
    case unknown
}

public enum DiagnosisScope: String, Sendable, Codable {
    case local
    case widespread
    case targetSpecific
    case none
    case unknown
}

public enum DiagnosisSeverity: String, Sendable, Codable {
    case healthy
    case degraded
    case poor
    case failed
    case offline
}

public struct Diagnosis: Sendable, Codable, Equatable {
    public let layer: DiagnosisLayer
    public let scope: DiagnosisScope
    public let severity: DiagnosisSeverity
    public let title: String
    public let summary: String

    public init(
        layer: DiagnosisLayer,
        scope: DiagnosisScope,
        severity: DiagnosisSeverity,
        title: String,
        summary: String)
    {
        self.layer = layer
        self.scope = scope
        self.severity = severity
        self.title = title
        self.summary = summary
    }
}
