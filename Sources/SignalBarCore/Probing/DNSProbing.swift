import Foundation

public protocol DNSProbing: Sendable {
    func probe(target: ProbeTarget) async -> DNSProbeResult
}
