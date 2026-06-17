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
{{#hbFluent}}
        .package(url: "https://github.com/hummingbird-project/hummingbird-fluent.git", from: "2.0.0"),
{{/hbFluent}}
{{#hbLambda}}
        .package(url: "https://github.com/hummingbird-project/hummingbird-lambda.git", from: "2.1.0"),
{{/hbLambda}}
{{#hbWebSocket}}
        .package(url: "https://github.com/hummingbird-project/hummingbird-websocket.git", from: "2.7.0"),
{{/hbWebSocket}}
        .package(url: "https://github.com/apple/swift-configuration.git", from: "1.0.0", traits: [.defaults, "CommandLineArguments"]),
{{#hbOpenAPI}}
        .package(url: "https://github.com/apple/swift-openapi-generator.git", from: "1.6.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime.git", from: "1.7.0"),
        .package(url: "https://github.com/hummingbird-project/swift-openapi-hummingbird.git", from: "2.0.1"),
{{/hbOpenAPI}}
{{#hbPostgresNIO}}
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.33.0"),
        .package(url: "https://github.com/hummingbird-project/postgres-migrations.git", from: "1.0.0"),
{{/hbPostgresNIO}}
{{#hbFluent}}
        .package(url: "https://github.com/vapor/fluent-kit.git", from: "1.56.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.12.0"),
{{/hbFluent}}
    ],
    targets: [
        .executableTarget(name: "{{hbExecutableName}}",
            dependencies: [
                .product(name: "Configuration", package: "swift-configuration"),
{{#hbFluent}}
                .product(name: "FluentKit", package: "fluent-kit"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
{{/hbFluent}}
                .product(name: "Hummingbird", package: "hummingbird"),
{{#hbFluent}}
                .product(name: "HummingbirdFluent", package: "hummingbird-fluent"),
{{/hbFluent}}
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
{{#hbPostgresNIO}}
                .product(name: "PostgresNIO", package: "postgres-nio"),
                .product(name: "PostgresMigrations", package: "postgres-migrations"),
{{/hbPostgresNIO}}
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
