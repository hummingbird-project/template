import Hummingbird
import Logging

/// Application arguments protocol. We use a protocol so we can call
/// `buildApplication` inside Tests as well as in the App executable. 
/// Any variables added here also have to be added to `App` in App.swift and 
/// `TestArguments` in AppTest.swift
public protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
    var logLevel: Logger.Level? { get }
}

public func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
    let logger = {
        var logger = Logger(label: "{{HB_PACKAGE_NAME}}")
        logger.logLevel = 
            arguments.logLevel ??
            Environment.shared.get("LOG_LEVEL").map { Logger.Level(rawValue: $0) ?? .info } ??
            .info
        return logger
    }()
    let router = Router()
    // Add logging
    router.add(middleware: LogRequestsMiddleware(.info))
    // Add health endpoint
    router.get("/health") { _,_ -> HTTPResponse.Status in
        return .ok
    }
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
