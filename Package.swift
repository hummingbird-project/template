// swift-tools-version:6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "{{hbPackageName}}",
{{^hbLambda}}
    platforms: [.macOS(.v15), .iOS(.v18), .tvOS(.v18)],
{{/hbLambda}}
{{#hbLambda}}
    platforms: [.macOS(.v15)],
{{/hbLambda}}
    products: [
        .executable(name: "{{hbExecutableName}}", targets: ["{{hbExecutableName}}"]),
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.25.0"),
{{#hbLambda}}
        .package(url: "https://github.com/hummingbird-project/hummingbird-lambda.git", from: "2.1.0"),
{{/hbLambda}}
{{#hbWebSocket}}
        .package(url: "https://github.com/hummingbird-project/hummingbird-websocket.git", from: "2.7.0"),
{{/hbWebSocket}}
        .package(url: "https://github.com/apple/swift-configuration.git", from: "1.0.0", traits: [.defaults, "CommandLineArguments"]),
{{#hbOpenAPI}}
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.6.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.7.0"),
        .package(url: "https://github.com/hummingbird-project/swift-openapi-hummingbird.git", from: "2.0.1"),
{{/hbOpenAPI}}
    ],
    targets: [
        .executableTarget(name: "{{hbExecutableName}}",
            dependencies: [
                .product(name: "Configuration", package: "swift-configuration"),
                .product(name: "Hummingbird", package: "hummingbird"),
{{#hbLambda}}
                .product(name: "HummingbirdLambda", package: "hummingbird-lambda"),
{{/hbLambda}}
{{#hbWebSocket}}
                .product(name: "HummingbirdWebSocket", package: "hummingbird-websocket"),
{{/hbWebSocket}}
{{#hbOpenAPI}}
                .byName(name: "{{hbExecutableName}}API"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIHummingbird", package: "swift-openapi-hummingbird"),
{{/hbOpenAPI}}
            ],
            path: "Sources/App"
        ),
{{#hbOpenAPI}}
        .target(
            name: "{{hbExecutableName}}API",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")
            ],
            path: "Sources/AppAPI",
            plugins: [.plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")]
        ),
{{/hbOpenAPI}}
        .testTarget(name: "{{hbExecutableName}}Tests",
            dependencies: [
                .byName(name: "{{hbExecutableName}}"),
{{^hbLambda}}
                .product(name: "HummingbirdTesting", package: "hummingbird"),
{{#hbWebSocket}}
                .product(name: "HummingbirdWSTesting", package: "hummingbird-websocket"),
{{/hbWebSocket}}
{{/hbLambda}}
{{#hbLambda}}
                .product(name: "HummingbirdLambdaTesting", package: "hummingbird-lambda"),
{{/hbLambda}}
            ],
            path: "Tests/AppTests"
        )
    ]
)
