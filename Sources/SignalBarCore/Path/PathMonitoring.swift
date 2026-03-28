import Foundation

public protocol PathMonitoring: Sendable {
    func stream() -> AsyncStream<PathSnapshot>
}
