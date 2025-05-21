// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "{{HB_PACKAGE_NAME}}",
    platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17)],
    products: [
        .executable(name: "{{HB_EXECUTABLE_NAME}}", targets: ["{{HB_EXECUTABLE_NAME}}"]),
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
{{#HB_OPENAPI}}
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.6.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.7.0"),
        .package(url: "https://github.com/swift-server/swift-openapi-hummingbird.git", from: "2.0.1"),
{{/HB_OPENAPI}}
    ],
    targets: [
        .executableTarget(name: "{{HB_EXECUTABLE_NAME}}",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Hummingbird", package: "hummingbird"),
{{#HB_OPENAPI}}
                .byName(name: "{{HB_EXECUTABLE_NAME}}API"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIHummingbird", package: "swift-openapi-hummingbird"),
{{/HB_OPENAPI}}
            ],
            path: "Sources/App"
        ),
{{#HB_OPENAPI}}
        .target(
            name: "{{HB_EXECUTABLE_NAME}}API",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")
            ],
            path: "Sources/AppAPI",
            plugins: [.plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")],
        ),
{{/HB_OPENAPI}}
        .testTarget(name: "{{HB_EXECUTABLE_NAME}}Tests",
            dependencies: [
                .byName(name: "{{HB_EXECUTABLE_NAME}}"),
                .product(name: "HummingbirdTesting", package: "hummingbird")
            ],
            path: "Tests/AppTests"
        )
    ]
)
