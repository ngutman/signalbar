// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SignalBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SignalBar", targets: ["SignalBar"])
    ],
    targets: [
        .target(
            name: "SignalBarCore",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]),
        .executableTarget(
            name: "SignalBar",
            dependencies: ["SignalBarCore"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]),
        .testTarget(
            name: "SignalBarCoreTests",
            dependencies: ["SignalBarCore"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]),
        .testTarget(
            name: "SignalBarTests",
            dependencies: ["SignalBar"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ])
    ])
