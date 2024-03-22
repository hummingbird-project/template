import Hummingbird

/// Application arguments protocol. We use a protocol so we can call
/// `HBApplication.configure` inside Tests as well as in the App executable. 
/// Any variables added here also have to be added to `App` in App.swift and 
/// `TestArguments` in AppTest.swift
public protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
}

public func buildApplication(_ arguments: some AppArguments) -> some ApplicationProtocol {
    let router = Router()
    router.get("/health") { _,_ -> HTTPResponse.Status in
        return .ok
    }
    let app = Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "Hummingbird"
        )
    )
    return app
}
