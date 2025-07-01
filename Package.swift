// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DifySwiftClient",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "DifySwiftClient",
            targets: ["DifySwiftClient"]),
    ],
    targets: [
        .target(
            name: "DifySwiftClient"),
        .testTarget(
            name: "DifySwiftClientTests",
            dependencies: ["DifySwiftClient"]
        ),
    ]
)
