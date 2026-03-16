// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LaunchDUI",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "LaunchDUI",
            path: "Sources/LaunchDUI"
        ),
        .testTarget(
            name: "LaunchDUITests",
            dependencies: ["LaunchDUI"],
            path: "Tests/LaunchDUITests"
        ),
    ]
)
