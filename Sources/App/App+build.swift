{{#hbLambda}}
import AWSLambdaEvents
{{/hbLambda}}
import Configuration
{{#hbFluent}}
import FluentPostgresDriver
{{/hbFluent}}
import Hummingbird
{{#hbFluent}}
import HummingbirdFluent
{{/hbFluent}}
{{#hbLambda}}
import HummingbirdLambda
{{/hbLambda}}
{{#hbWebSocket}}
import HummingbirdWebSocket
{{/hbWebSocket}}
import Logging
{{#hbOpenAPI}}
import OpenAPIHummingbird
{{/hbOpenAPI}}
{{#hbPostgresNIO}}
import PostgresMigrations
import PostgresNIO
{{/hbPostgresNIO}}

// Request context used by {{^hbLambda}}application{{/hbLambda}}{{#hbLambda}}lambda<{{hbLambdaType}}Request>{{/hbLambda}}
typealias AppRequestContext = {{^hbLambda}}BasicRequestContext{{/hbLambda}}{{#hbLambda}}BasicLambdaRequestContext<{{hbLambdaType}}Request>{{/hbLambda}}
{{#hbWebSocket}}
typealias AppWSRequestContext = BasicWebSocketRequestContext
{{/hbWebSocket}}

{{^hbLambda}}
///  Build application
/// - Parameter reader: configuration reader
func buildApplication(reader: ConfigReader) async throws -> some ApplicationProtocol {
{{/hbLambda}}
{{#hbLambda}}
///  Build AWS Lambda function
/// - Parameter reader: configuration reader
func buildLambda(reader: ConfigReader) async throws -> {{hbLambdaType}}LambdaFunction<RouterResponder<AppRequestContext>> {
{{/hbLambda}}
    let logger = {
        var logger = Logger(label: "{{hbPackageName}}")
        logger.logLevel = reader.string(forKey: "log.level", as: Logger.Level.self, default: .info)
        return logger
    }()
{{#hbPostgresNIO}}
    // Postgres client
    let postgresClient = try PostgresClient(
        configuration: .init(
            host: reader.string(forKey: "postgres.host", default: "127.0.0.1"),
            port: reader.int(forKey: "postgres.port", default: 5432),
            username: reader.requiredString(forKey: "postgres.user"),
            password: reader.requiredString(forKey: "postgres.password"),
            database: reader.requiredString(forKey: "postgres.database"),
            tls: .disable
        )
    )
    let migrations = DatabaseMigrations()
{{/hbPostgresNIO}}
{{#hbFluent}}
    let fluent = Fluent(logger: logger)
    try fluent.databases.use(
        .postgres(
            configuration: .init(
                hostname: reader.string(forKey: "postgres.host", default: "127.0.0.1"),
                port: reader.int(forKey: "postgres.port", default: 5432),
                username: reader.requiredString(forKey: "postgres.user"),
                password: reader.requiredString(forKey: "postgres.password"),
                database: reader.requiredString(forKey: "postgres.database"),
                tls: .disable
            )
        ),
        as: .psql
    )
{{/hbFluent}}
{{#hbPostgresNIO}}
    // Only run database migration once all migrations have been added
    if reader.bool(forKey: "db.migrate") == true {
        try await databaseMigrate(postgresClient: postgresClient, migrations: migrations, logger: logger)
    }
    // Database migration service: verifies all migrations have been applied
    let databaseMigrationService = DatabaseMigrationService(
        client: postgresClient, 
        migrations: migrations, 
        logger: logger,
        dryRun: true
    )
{{/hbPostgresNIO}}
{{#hbFluent}}
    // Only run database migration once all migrations have been added
    if reader.bool(forKey: "db.migrate") == true {
        logger.info("Running database migrations")
        try await fluent.migrate()
        exit(0)
    }
{{/hbFluent}}
{{#first(hbRouterParams)}}
    let router = try buildRouter(
{{#hbRouterParams}}
        {{.}}: {{.}}{{^last()}},{{/last()}}
{{/hbRouterParams}}
    )
{{/first(hbRouterParams)}}
{{^first(hbRouterParams)}}
    let router = try buildRouter()
{{/first(hbRouterParams)}}
{{#hbWebSocket}}
    let wsRouter = try buildWebSocketRouter()
{{/hbWebSocket}}
{{^hbLambda}}
    let app = Application(
        router: router,
{{#hbWebSocket}}
        server: .http1WebSocketUpgrade(webSocketRouter: wsRouter),
{{/hbWebSocket}}
        configuration: ApplicationConfiguration(reader: reader.scoped(to: "http")),
{{#first(hbServices)}}
        services: [{{#hbServices}}{{.}}{{^last()}}, {{/last()}}{{/hbServices}}],
{{/first(hbServices)}}
        logger: logger
    )
    return app
{{/hbLambda}}
{{#hbLambda}}
    let lambda = {{hbLambdaType}}LambdaFunction(
        router: router,
{{#first(hbServices)}}
        services: [{{#hbServices}}{{.}}{{^last()}}, {{/last()}}{{/hbServices}}],
{{/first(hbServices)}}
        logger: logger
    )
    return lambda
{{/hbLambda}}
}

/// Build router
{{#first(hbRouterParamTypes)}}
func buildRouter(
{{#hbRouterParamTypes}}
    {{.}}{{^last()}},{{/last()}}
{{/hbRouterParamTypes}}
) throws -> Router<AppRequestContext> {
{{/first(hbRouterParamTypes)}}
{{^first(hbRouterParamTypes)}}
func buildRouter() throws -> Router<AppRequestContext> {
{{/first(hbRouterParamTypes)}}
    let router = Router(context: AppRequestContext.self)
    // Add middleware
    router.addMiddleware {
        // logging middleware
        LogRequestsMiddleware(.info)
{{#hbOpenAPI}}
        // store request context in TaskLocal
        OpenAPIRequestContextMiddleware()
{{/hbOpenAPI}}
    }
{{#hbOpenAPI}}
    // Add OpenAPI handlers
    let api = APIImplementation()
    try api.registerHandlers(on: router)
{{/hbOpenAPI}}
{{^hbOpenAPI}}
    // Add default endpoint
    router.get("/") { _,_ in
        return "Hello!"
    }
{{/hbOpenAPI}}
    return router
}
{{#hbWebSocket}}

/// Build websocket router
{{#first(hbRouterParamTypes)}}
func buildWebSocketRouter(
{{#hbRouterParamTypes}}
    {{.}}{{^last()}},{{/last()}}
{{/hbRouterParamTypes}}
) throws -> Router<AppWSRequestContext> {
{{/first(hbRouterParamTypes)}}
{{^first(hbRouterParamTypes)}}
func buildWebSocketRouter() throws -> Router<AppWSRequestContext> {
{{/first(hbRouterParamTypes)}}
    let router = Router(context: AppWSRequestContext.self)
    // Add middleware
    router.addMiddleware {
        // logging middleware
        LogRequestsMiddleware(.info)
    }
    // Add default endpoint
    router.ws("/ws") { request, context in
        return .upgrade()
    } onUpgrade: { inbound, outbound, context in
        // Read inbound message
        for try await message in inbound.messages(maxSize: 1_000_000) {
            // write type and size of message
            switch message {
            case .binary(let buffer):
                try await outbound.write(.text("Binary message, length: \(buffer.readableBytes)"))
            case .text(let string):
                try await outbound.write(.text("Text message, length: \(string.count)"))
            }
        }
    }
    return router
}
{{/hbWebSocket}}
{{#hbPostgresNIO}}

/// Perform database migration and exit
func databaseMigrate(postgresClient: PostgresClient, migrations: DatabaseMigrations, logger: Logger) async throws -> Never {
    logger.info("Running database migrations")
    async let _ = postgresClient.run()
    try await migrations.apply(client: postgresClient, logger: logger, dryRun: false)
    exit(0)
}
{{/hbPostgresNIO}}
