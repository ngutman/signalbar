import Foundation

private final class HTTPMetricsDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var collectedMetrics: URLSessionTaskMetrics?

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        lock.lock()
        collectedMetrics = metrics
        lock.unlock()
    }

    var metrics: URLSessionTaskMetrics? {
        lock.lock()
        defer { self.lock.unlock() }
        return collectedMetrics
    }
}

public struct HTTPProbeRunner: HTTPProbing {
    public init() {}

    public func probe(target: ProbeTarget) async -> HTTPProbeResult {
        await probe(target: target, method: initialMethod(for: target))
    }

    private func probe(target: ProbeTarget, method: String) async -> HTTPProbeResult {
        let delegate = HTTPMetricsDelegate()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.timeoutIntervalForRequest = target.timeout
        configuration.timeoutIntervalForResource = target.timeout
        configuration.waitsForConnectivity = false

        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        defer {
            session.finishTasksAndInvalidate()
        }

        var request = URLRequest(url: target.url)
        request.httpMethod = method
        request.timeoutInterval = target.timeout
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let startedAt = Date()
        do {
            let (_, response) = try await session.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode

            if method == "HEAD", target.method == .auto, statusCode == 405 || statusCode == 501 {
                return await probe(target: target, method: "GET")
            }

            let success = isSuccess(statusCode: statusCode, target: target)
            return makeResult(
                targetID: target.id,
                startedAt: startedAt,
                statusCode: statusCode,
                success: success,
                metrics: delegate.metrics,
                failure: success ? nil : .badStatus)
        } catch {
            return makeResult(
                targetID: target.id,
                startedAt: startedAt,
                statusCode: nil,
                success: false,
                metrics: delegate.metrics,
                failure: classify(error: error))
        }
    }

    private func initialMethod(for target: ProbeTarget) -> String {
        switch target.method {
        case .auto, .head:
            "HEAD"
        case .get:
            "GET"
        }
    }

    private func isSuccess(statusCode: Int?, target: ProbeTarget) -> Bool {
        guard let statusCode else { return false }
        if let expectedStatusCodes = target.expectedStatusCodes, !expectedStatusCodes.isEmpty {
            return expectedStatusCodes.contains(statusCode)
        }
        if (200 ... 299).contains(statusCode) {
            return true
        }
        if target.treatHTTP3xxAsSuccess, (300 ... 399).contains(statusCode) {
            return true
        }
        return false
    }

    private func classify(error: Error) -> HTTPProbeFailure {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return .timeout
            case .cannotFindHost, .dnsLookupFailed:
                return .dns
            case .cannotConnectToHost, .notConnectedToInternet, .networkConnectionLost:
                return .connect
            case .secureConnectionFailed, .serverCertificateHasBadDate, .serverCertificateUntrusted,
                 .serverCertificateHasUnknownRoot, .serverCertificateNotYetValid, .clientCertificateRejected,
                 .clientCertificateRequired:
                return .tls
            case .cancelled:
                return .cancelled
            default:
                return .unknown
            }
        }
        return .unknown
    }

    private func makeResult(
        targetID: UUID,
        startedAt: Date,
        statusCode: Int?,
        success: Bool,
        metrics: URLSessionTaskMetrics?,
        failure: HTTPProbeFailure?) -> HTTPProbeResult
    {
        let transactionMetric = metrics?.transactionMetrics.last
        return HTTPProbeResult(
            targetID: targetID,
            startedAt: startedAt,
            dnsMs: durationMs(
                from: transactionMetric?.domainLookupStartDate,
                to: transactionMetric?.domainLookupEndDate),
            connectMs: durationMs(from: transactionMetric?.connectStartDate, to: transactionMetric?.connectEndDate),
            tlsMs: durationMs(
                from: transactionMetric?.secureConnectionStartDate,
                to: transactionMetric?.secureConnectionEndDate),
            firstByteMs: durationMs(
                from: transactionMetric?.requestStartDate,
                to: transactionMetric?.responseStartDate),
            totalMs: metrics.map { $0.taskInterval.duration * 1000 },
            statusCode: statusCode,
            success: success,
            reusedConnection: transactionMetric?.isReusedConnection ?? false,
            failure: failure)
    }

    private func durationMs(from start: Date?, to end: Date?) -> Double? {
        guard let start, let end else { return nil }
        return max(0, end.timeIntervalSince(start) * 1000)
    }
}
