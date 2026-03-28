import Foundation
import Network

public struct PathMonitorService: PathMonitoring {
    public init() {}

    public func stream() -> AsyncStream<PathSnapshot> {
        AsyncStream { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "dev.signalbar.path-monitor")

            monitor.pathUpdateHandler = { path in
                continuation.yield(Self.snapshot(from: path))
            }

            monitor.start(queue: queue)
            continuation.onTermination = { _ in
                monitor.cancel()
            }
        }
    }

    private static func snapshot(from path: NWPath) -> PathSnapshot {
        PathSnapshot(
            observedAt: .now,
            status: status(from: path.status),
            interface: interfaceKind(from: path),
            isConstrained: path.isConstrained,
            isExpensive: path.isExpensive,
            supportsDNS: path.supportsDNS,
            supportsIPv4: path.supportsIPv4,
            supportsIPv6: path.supportsIPv6)
    }

    private static func status(from status: NWPath.Status) -> PathStatus {
        switch status {
        case .satisfied:
            .satisfied
        case .unsatisfied:
            .unsatisfied
        case .requiresConnection:
            .requiresConnection
        @unknown default:
            .unsatisfied
        }
    }

    private static func interfaceKind(from path: NWPath) -> InterfaceKind? {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        }
        if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        }
        if path.usesInterfaceType(.cellular) {
            return .cellular
        }
        let hasAnyInterface = !path.availableInterfaces.isEmpty
        return hasAnyInterface ? .other : nil
    }
}
