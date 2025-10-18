// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "{{hbPackageName}}",
{{^hbLambda}}
    platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17)],
{{/hbLambda}}
{{#hbLambda}}
    platforms: [.macOS(.v15)],
{{/hbLambda}}
    products: [
        .executable(name: "{{hbExecutableName}}", targets: ["{{hbExecutableName}}"]),
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
{{#hbLambda}}
        .package(url: "https://github.com/hummingbird-project/hummingbird-lambda.git", from: "2.0.0"),
{{/hbLambda}}
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
{{#hbOpenAPI}}
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.6.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.7.0"),
        .package(url: "https://github.com/hummingbird-project/swift-openapi-hummingbird.git", from: "2.0.1"),
{{/hbOpenAPI}}
    ],
    targets: [
        .executableTarget(name: "{{hbExecutableName}}",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Hummingbird", package: "hummingbird"),
{{#hbLambda}}
                .product(name: "HummingbirdLambda", package: "hummingbird-lambda"),
{{/hbLambda}}
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
                .product(name: "HummingbirdTesting", package: "hummingbird")
{{/hbLambda}}
{{#hbLambda}}
                .product(name: "HummingbirdLambdaTesting", package: "hummingbird-lambda"),
{{/hbLambda}}
            ],
            path: "Tests/AppTests"
        )
    ]
)
