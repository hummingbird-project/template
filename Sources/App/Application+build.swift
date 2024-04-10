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

public func buildApplication(_ arguments: some AppArguments) -> some ApplicationProtocol {
    let logger = {
        var logger = Logger(label: "HB")
        logger.logLevel = arguments.logLevel ?? .info
        return logger
    }()
    let router = Router()
    // Add health route
    router.get("/health") { _,_ -> HTTPResponse.Status in
        return .ok
    }
    let app = Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "Hummingbird"
        ),
        logger: logger
    )
    return app
}
