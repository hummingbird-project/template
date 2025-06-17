import Hummingbird
import Logging
{{#HB_OPENAPI}}
import OpenAPIHummingbird
{{/HB_OPENAPI}}

/// Application arguments protocol. We use a protocol so we can call
/// `buildApplication` inside Tests as well as in the App executable. 
/// Any variables added here also have to be added to `App` in App.swift and 
/// `TestArguments` in AppTest.swift
public protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
    var logLevel: Logger.Level? { get }
}

// Request context used by application
typealias AppRequestContext = BasicRequestContext

///  Build application
/// - Parameter arguments: application arguments
public func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
    let environment = Environment()
    let logger = {
        var logger = Logger(label: "{{HB_PACKAGE_NAME}}")
        logger.logLevel = 
            arguments.logLevel ??
            environment.get("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) } ??
            .info
        return logger
    }()
    let router = try buildRouter()
    let app = Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "{{HB_PACKAGE_NAME}}"
        ),
        logger: logger
    )
    return app
}

/// Build router
func buildRouter() throws -> Router<AppRequestContext> {
    let router = Router(context: AppRequestContext.self)
    // Add middleware
    router.addMiddleware {
        // logging middleware
        LogRequestsMiddleware(.info)
{{#HB_OPENAPI}}
        // store request context in TaskLocal
        OpenAPIRequestContextMiddleware()
{{/HB_OPENAPI}}
    }
{{#HB_OPENAPI}}
    // Add OpenAPI handlers
    let api = APIImplementation()
    try api.registerHandlers(on: router)
{{/HB_OPENAPI}}
{{^HB_OPENAPI}}
    // Add default endpoint
    router.get("/") { _,_ in
        return "Hello!"
    }
{{/HB_OPENAPI}}
    return router
}
