import Hummingbird

/// Application arguments protocol. We use a protocol so we can call
/// `HBApplication.configure` inside Tests. Any variables added here
/// also have to be added to 
public protocol AppArguments {
// add any arguments you need to pass to `HBApplication.configure`
}

extension HBApplication {
    /// configure your application
    /// add middleware
    /// setup the encoder/decoder
    /// add your routes
    func configure(_ args: AppArguments) throws {
        self.router.get("/health") { _ -> HTTPResponseStatus in
            return .ok
        }
    }
}
