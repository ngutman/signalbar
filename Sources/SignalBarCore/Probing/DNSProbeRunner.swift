import Darwin
import Foundation

private final class DNSProbeCompletionBox: @unchecked Sendable {
    private let lock = NSLock()
    private var hasResumed = false

    func resume(_ continuation: CheckedContinuation<DNSProbeResult, Never>, with result: DNSProbeResult) {
        lock.lock()
        defer { self.lock.unlock() }
        guard !hasResumed else { return }
        hasResumed = true
        continuation.resume(returning: result)
    }
}

public struct DNSProbeRunner: DNSProbing {
    private let queue: DispatchQueue

    public init(queue: DispatchQueue = DispatchQueue(label: "dev.signalbar.dns-probe", attributes: .concurrent)) {
        self.queue = queue
    }

    public func probe(target: ProbeTarget) async -> DNSProbeResult {
        let startedAt = Date()
        let startedReference = CFAbsoluteTimeGetCurrent()

        return await withCheckedContinuation { continuation in
            let completionBox = DNSProbeCompletionBox()

            queue.async {
                let resolution = Self.resolve(host: target.host)
                let durationMs = max(0, (CFAbsoluteTimeGetCurrent() - startedReference) * 1000)
                let result = DNSProbeResult(
                    targetID: target.id,
                    startedAt: startedAt,
                    durationMs: durationMs,
                    success: resolution.success,
                    resolvedAddresses: resolution.resolvedAddresses,
                    failure: resolution.failure)
                completionBox.resume(continuation, with: result)
            }

            queue.asyncAfter(deadline: .now() + target.timeout) {
                let timeoutResult = DNSProbeResult(
                    targetID: target.id,
                    startedAt: startedAt,
                    durationMs: max(0, target.timeout * 1000),
                    success: false,
                    resolvedAddresses: 0,
                    failure: .timeout)
                completionBox.resume(continuation, with: timeoutResult)
            }
        }
    }

    private static func resolve(host: String) -> (success: Bool, resolvedAddresses: Int, failure: DNSFailure?) {
        var hints = addrinfo(
            ai_flags: AI_ADDRCONFIG,
            ai_family: AF_UNSPEC,
            ai_socktype: SOCK_STREAM,
            ai_protocol: IPPROTO_TCP,
            ai_addrlen: 0,
            ai_canonname: nil,
            ai_addr: nil,
            ai_next: nil)
        var resultPointer: UnsafeMutablePointer<addrinfo>?
        let status = host.withCString { hostCString in
            getaddrinfo(hostCString, nil, &hints, &resultPointer)
        }

        defer {
            if let resultPointer {
                freeaddrinfo(resultPointer)
            }
        }

        guard status == 0 else {
            return (false, 0, failure(for: status))
        }

        var addressCount = 0
        var current = resultPointer
        while current != nil {
            addressCount += 1
            current = current?.pointee.ai_next
        }

        if addressCount == 0 {
            return (false, 0, .noRecords)
        }
        return (true, addressCount, nil)
    }

    private static func failure(for status: Int32) -> DNSFailure {
        switch status {
        case EAI_NONAME:
            .noRecords
        case EAI_AGAIN:
            .timeout
        case EAI_FAIL, EAI_SYSTEM:
            .resolverFailure
        default:
            .unknown
        }
    }
}
