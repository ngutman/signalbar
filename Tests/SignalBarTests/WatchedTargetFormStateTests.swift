import Foundation
@testable import SignalBar
import SignalBarCore
import XCTest

final class WatchedTargetFormStateTests: XCTestCase {
    func test_blankNameFallsBackToHost() throws {
        let existing = ProbeTarget(
            id: UUID(),
            kind: .watched,
            name: "Existing",
            url: URL(string: "https://old.example.com")!,
            method: .auto,
            interval: 15,
            timeout: 3.0)
        let state = WatchedTargetFormState(
            name: "   ",
            urlText: "https://github.com/features",
            errorMessage: nil)

        let target = try state.makeTarget(existingTarget: existing)
        XCTAssertEqual(target.id, existing.id)
        XCTAssertEqual(target.name, "github.com")
        XCTAssertEqual(target.url.absoluteString, "https://github.com/features")
    }

    func test_invalidSchemeFailsValidation() {
        let state = WatchedTargetFormState(name: "Local", urlText: "ftp://example.com", errorMessage: nil)

        XCTAssertThrowsError(try state.makeTarget(existingTarget: nil)) { error in
            XCTAssertEqual(error as? WatchedTargetFormState.ValidationError, .unsupportedScheme)
        }
    }

    func test_missingHostFailsValidation() {
        let state = WatchedTargetFormState(name: "Broken", urlText: "https:///path-only", errorMessage: nil)

        XCTAssertThrowsError(try state.makeTarget(existingTarget: nil)) { error in
            XCTAssertEqual(error as? WatchedTargetFormState.ValidationError, .missingHost)
        }
    }

    func test_emptyURLFailsValidation() {
        let state = WatchedTargetFormState(name: "", urlText: "   ", errorMessage: nil)

        XCTAssertThrowsError(try state.makeTarget(existingTarget: nil)) { error in
            XCTAssertEqual(error as? WatchedTargetFormState.ValidationError, .emptyURL)
        }
    }
}
