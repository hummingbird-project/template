{{#hbLambda}}
import AWSLambdaEvents
{{/hbLambda}}
import Configuration
import Hummingbird
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
    let router = try buildRouter()
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
        logger: logger
    )
    return app
{{/hbLambda}}
{{#hbLambda}}
    let lambda = {{hbLambdaType}}LambdaFunction(
        router: router,
        logger: logger
    )
    return lambda
{{/hbLambda}}
}

/// Build router
func buildRouter() throws -> Router<AppRequestContext> {
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
func buildWebSocketRouter() throws -> Router<AppWSRequestContext> {
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
        for try await message in inbound.messages(maxSize: 1_000_000) {
            switch message {
            case .binary(let buffer):
                try await outbound.write(.text("Received binary message, length \(buffer.readableBytes)"))
            case .text(let string):
                try await outbound.write(.text("Received text message, length \(string.count)"))
            }
        }
    }
    return router
}
{{/hbWebSocket}}
