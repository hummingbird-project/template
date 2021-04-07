import Hummingbird

extension HBApplication {
    /// configure your application
    /// add middleware
    /// setup the encoder/decoder
    /// add your routes
    public func configure() {
        self.router.get("/health") { _ -> HTTPResponseStatus in
            return .ok
        }
    }
}
