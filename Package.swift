// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LaunchdUI",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "LaunchdUI",
            path: "Sources/LaunchdUI"
        ),
        .testTarget(
            name: "LaunchdUITests",
            dependencies: ["LaunchdUI"],
            path: "Tests/LaunchdUITests"
        ),
    ]
)
