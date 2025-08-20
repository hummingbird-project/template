import Hummingbird

/// A middleware that handles errors.
/// By being generic over any RequestContext, this middleware can be used regardless of
/// the type of RequestContext.
/// This is a simple example, and translates unknown errors into a 500 error. You might prefer
/// to change the message to include the error description only when in DEBUG.
struct ErrorMiddleware<Context: RequestContext>: RouterMiddleware {
    func handle(
        _ input: Request,
        context: Context,
        next: (Request, Context) async throws -> Response
    ) async throws -> Response {
        do {
            return try await next(input, context)
        } catch let error as HTTPError {
            throw error
        } catch {
            throw HTTPError(.internalServerError, message: "Error: \(error)")
        }
    }
}
