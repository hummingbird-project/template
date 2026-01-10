import Configuration
import Hummingbird
{{^hbLambda}}
import HummingbirdTesting
{{/hbLambda}}
{{#hbLambda}}
import HummingbirdLambdaTesting
{{/hbLambda}}
import Logging
import Testing

@testable import {{hbExecutableName}}

{{^hbLambda}}
private let reader = ConfigReader(providers: [
    InMemoryProvider(values: [
        "http.host": "127.0.0.1",
        "http.port": "0",
        "log.level": "trace"
    ])
])
{{/hbLambda}}
{{#hbLambda}}
private let reader = ConfigReader(providers: [
    InMemoryProvider(values: [
        "log.level": "trace"
    ])
])
{{/hbLambda}}

@Suite
struct AppTests {
{{^hbLambda}}
    @Test
    func app() async throws {
        let app = try await buildApplication(reader: reader)
        try await app.test(.router) { client in
            try await client.execute(uri: "/", method: .get) { response in
                #expect(response.body == ByteBuffer(string: "Hello!"))
            }
        }
    }
{{/hbLambda}}
{{#hbLambda}}
    @Test
    func lambda() async throws {
        let lambda = try await buildLambda(reader: reader)
        try await lambda.test() { client in
            try await client.execute(uri: "/", method: .get) { response in
                #expect(response.body == "Hello!")
            }
        }
    }
{{/hbLambda}}
}
