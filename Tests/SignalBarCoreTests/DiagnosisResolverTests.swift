@testable import SignalBarCore
import XCTest

final class DiagnosisResolverTests: XCTestCase {
    func test_dnsFailureTakesPriority() {
        let diagnosis = DiagnosisResolver.diagnosis(
            dnsStatus: .failed,
            internetStatus: .failed,
            qualityStatus: .failed,
            internetSuccessRate: 0)

        XCTAssertEqual(diagnosis.layer, .dns)
        XCTAssertEqual(diagnosis.severity, .failed)
    }

    func test_watchedTargetIssueOverridesHealthyCoreDiagnosis() {
        let target = ProbeTarget(
            id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
            kind: .watched,
            name: "GitHub",
            url: URL(string: "https://github.com")!,
            method: .auto,
            interval: 15,
            timeout: 3.0)
        let watchedTarget = TargetHealth(
            id: target.id,
            target: target,
            medianLatencyMs: nil,
            jitterMs: nil,
            successRate: 0,
            lastFailureText: "Timeout",
            latestHTTP: HTTPProbeResult(
                targetID: target.id,
                startedAt: .now,
                dnsMs: nil,
                connectMs: nil,
                tlsMs: nil,
                firstByteMs: nil,
                totalMs: 3000,
                statusCode: nil,
                success: false,
                reusedConnection: false,
                failure: .timeout),
            latestDNS: nil)

        let diagnosis = DiagnosisResolver.withWatchedTarget(
            base: DiagnosisResolver.diagnosis(
                dnsStatus: .healthy,
                internetStatus: .healthy,
                qualityStatus: .healthy,
                internetSuccessRate: 1.0),
            watchedTargetHealth: watchedTarget,
            internetStatus: .healthy,
            qualityStatus: .healthy)

        XCTAssertEqual(diagnosis.layer, .watchedService)
        XCTAssertEqual(diagnosis.scope, .targetSpecific)
    }
}
