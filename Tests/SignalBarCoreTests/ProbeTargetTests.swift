@testable import SignalBarCore
import XCTest

final class ProbeTargetTests: XCTestCase {
    func test_defaultControlTargetsMatchExpectedNamesAndHosts() throws {
        let targets = ProbeTarget.defaultControlTargets

        XCTAssertEqual(targets.map(\.name), ["Apple", "Cloudflare", "Google"])
        XCTAssertEqual(targets.map(\.host), [
            "www.apple.com",
            "cp.cloudflare.com",
            "www.google.com"
        ])
        XCTAssertTrue(targets.allSatisfy { $0.kind == .control })
        XCTAssertTrue(targets.allSatisfy { $0.method == .head })
        XCTAssertEqual(targets.map(\.expectedStatusCodes), [[200], [204], [204]])
    }
}
