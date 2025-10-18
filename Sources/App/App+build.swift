{{#hbLambda}}
import AWSLambdaEvents
{{/hbLambda}}
import Hummingbird
{{#hbLambda}}
import HummingbirdLambda
{{/hbLambda}}
import Logging
{{#hbOpenAPI}}
import OpenAPIHummingbird
{{/hbOpenAPI}}

{{^hbLambda}}
/// Application arguments protocol. We use a protocol so we can call
/// `buildApplication` inside Tests as well as in the App executable. 
/// Any variables added here also have to be added to `App` in App.swift and 
/// `TestArguments` in AppTest.swift
package protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
    var logLevel: Logger.Level? { get }
}
{{/hbLambda}}

// Request context used by {{^hbLambda}}application{{/hbLambda}}{{#hbLambda}}lambda<APIGatewayV2Request>{{/hbLambda}}
typealias AppRequestContext = {{^hbLambda}}BasicRequestContext{{/hbLambda}}{{#hbLambda}}BasicLambdaRequestContext<APIGatewayV2Request>{{/hbLambda}}

{{^hbLambda}}
///  Build application
/// - Parameter arguments: application arguments
func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
{{/hbLambda}}
{{#hbLambda}}
///  Build AWS Lambda function
func buildLambda() async throws -> APIGatewayV2LambdaFunction<RouterResponder<AppRequestContext>> {
{{/hbLambda}}
    let environment = Environment()
    let logger = {
        var logger = Logger(label: "{{hbPackageName}}")
        logger.logLevel = 
{{^hbLambda}}
            arguments.logLevel ??
{{/hbLambda}}
            environment.get("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) } ??
            .info
        return logger
    }()
    let router = try buildRouter()
{{^hbLambda}}
    let app = Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "{{hbPackageName}}"
        ),
        logger: logger
    )
    return app
{{/hbLambda}}
{{#hbLambda}}
    let lambda = APIGatewayV2LambdaFunction(
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
