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
    dependencies: [
        // Swift OpenAPI Generator - Build-time code generation
        .package(
            url: "https://github.com/apple/swift-openapi-generator",
            from: "1.6.0"
        ),
        // Swift OpenAPI Runtime - Runtime library for generated code
        .package(
            url: "https://github.com/apple/swift-openapi-runtime",
            from: "1.7.0"
        ),
        // URLSession-based transport for HTTP client
        .package(
            url: "https://github.com/apple/swift-openapi-urlsession",
            from: "1.0.0"
        ),
    ],
    targets: [
        .target(
            name: "DifySwiftClient",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
            ],
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        ),
        .testTarget(
            name: "DifySwiftClientTests",
            dependencies: ["DifySwiftClient"]
        ),
    ]
)
