import Hummingbird

public protocol AppArguments {
// add any arguments you need to pass to the configure
}

extension HBApplication {
    /// configure your application
    /// add middleware
    /// setup the encoder/decoder
    /// add your routes
    public func configure(_ args: AppArguments) throws {
        self.router.get("/health") { _ -> HTTPResponseStatus in
            return .ok
        }
    }
}
