{{#hbOpenAPI}}
import {{hbExecutableName}}API
import OpenAPIRuntime

struct APIImplementation: APIProtocol {
    func getHello(_ input: {{hbExecutableName}}API.Operations.GetHello.Input) async throws -> {{hbExecutableName}}API.Operations.GetHello.Output {
        return .ok(.init(body: .plainText("Hello!")))
    }
}
{{/hbOpenAPI}}
