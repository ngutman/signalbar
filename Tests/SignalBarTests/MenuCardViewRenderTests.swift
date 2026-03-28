import AppKit
@testable import SignalBar
import SwiftUI
import XCTest

@MainActor
final class MenuCardViewRenderTests: XCTestCase {
    func test_menuCardViewRendersHealthyPreviewAtExpectedSize() throws {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = HealthStore(sourceMode: .preview, userDefaults: defaults)
        store.setPreviewScenario(.healthy)
        store.setHistoryMetric(.ping)
        store.setTimelineWindow(.oneMinute)

        let view = MenuOverviewCardView(store: store, width: 456)
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(x: 0, y: 0, width: 456, height: 10)
        hostingView.layoutSubtreeIfNeeded()

        let fittingSize = hostingView.fittingSize
        XCTAssertGreaterThan(fittingSize.height, 300)
        XCTAssertLessThan(fittingSize.height, 900)

        if ProcessInfo.processInfo.environment["SIGNALBAR_WRITE_RENDER"] == "1" {
            try writeRenderIfRequested(view: hostingView, size: fittingSize, name: "preview")
        }
    }

    func test_menuCardRendersOverviewModeAtExpectedSize() throws {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = HealthStore(sourceMode: .preview, userDefaults: defaults)
        store.setPreviewScenario(.qualityDegraded)
        store.setHistoryMetric(.overview)
        store.setTimelineWindow(.fiveMinutes)

        let view = MenuOverviewCardView(store: store, width: 456)
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(x: 0, y: 0, width: 456, height: 10)
        hostingView.layoutSubtreeIfNeeded()

        let fittingSize = hostingView.fittingSize
        XCTAssertGreaterThan(fittingSize.height, 300)
        XCTAssertLessThan(fittingSize.height, 900)

        if ProcessInfo.processInfo.environment["SIGNALBAR_WRITE_RENDER"] == "1" {
            try writeRenderIfRequested(view: hostingView, size: fittingSize, name: "overview")
        }
    }

    func test_menuCardRendersReliabilityModeAtExpectedSize() throws {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = HealthStore(sourceMode: .preview, userDefaults: defaults)
        store.setPreviewScenario(.internetFailure)
        store.setHistoryMetric(.reliability)

        let view = MenuOverviewCardView(store: store, width: 456)
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(x: 0, y: 0, width: 456, height: 10)
        hostingView.layoutSubtreeIfNeeded()

        let reliabilityHeight = hostingView.fittingSize.height

        XCTAssertGreaterThan(reliabilityHeight, 300)
        XCTAssertLessThan(reliabilityHeight, 900)

        if ProcessInfo.processInfo.environment["SIGNALBAR_WRITE_RENDER"] == "1" {
            try writeRenderIfRequested(view: hostingView, size: hostingView.fittingSize, name: "reliability")
        }
    }

    func test_menuCardViewRendersEmptyLiveStateAtExpectedSize() throws {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = HealthStore(userDefaults: defaults)
        let view = MenuOverviewCardView(store: store, width: 456)
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(x: 0, y: 0, width: 456, height: 10)
        hostingView.layoutSubtreeIfNeeded()

        let fittingSize = hostingView.fittingSize
        XCTAssertGreaterThan(fittingSize.height, 300)
        XCTAssertLessThan(fittingSize.height, 900)

        if ProcessInfo.processInfo.environment["SIGNALBAR_WRITE_RENDER"] == "1" {
            try writeRenderIfRequested(view: hostingView, size: fittingSize, name: "empty-live")
        }
    }

    private func fittingHeight(for store: HealthStore) -> CGFloat {
        let view = MenuOverviewCardView(store: store, width: 456)
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(x: 0, y: 0, width: 456, height: 10)
        hostingView.layoutSubtreeIfNeeded()
        return hostingView.fittingSize.height
    }

    private func writeRenderIfRequested(view: NSView, size: NSSize, name: String) throws {
        let image = try XCTUnwrap(renderImage(for: view, size: size))
        let outputURL = URL(fileURLWithPath: "/tmp/signalbar-menu-card-\(name).png")
        try image.pngData()?.write(to: outputURL)
        print("wrote render to \(outputURL.path)")
    }

    private func renderImage(for view: NSView, size: NSSize) -> NSImage? {
        view.frame = NSRect(origin: .zero, size: size)
        view.layoutSubtreeIfNeeded()

        guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
            return nil
        }
        view.cacheDisplay(in: view.bounds, to: bitmap)

        let image = NSImage(size: size)
        image.addRepresentation(bitmap)
        return image
    }
}

private extension NSImage {
    func pngData() -> Data? {
        guard let tiffData = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData)
        else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }
}
