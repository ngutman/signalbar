import Foundation

public protocol HTTPProbing: Sendable {
    func probe(target: ProbeTarget) async -> HTTPProbeResult
}
