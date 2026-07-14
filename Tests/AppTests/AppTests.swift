import Configuration
import Hummingbird
{{^hbLambda}}
import HummingbirdTesting
{{#hbWebSocket}}
import HummingbirdWSTesting
{{/hbWebSocket}}
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
        "log.level": "trace",
{{#hbPostgres}}
        // Postgres database setup
        "postgres.host": "127.0.0.1",
        "postgres.user": "hb",
        "postgres.password": "testing123",
        "postgres.database": "hb",
{{/hbPostgres}}
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
    func hello() async throws {
        let app = try await buildApplication(reader: reader)
        try await app.test(.router) { client in
            try await client.execute(uri: "/", method: .get) { response in
                #expect(response.body == ByteBuffer(string: "Hello!"))
            }
        }
    }
{{#hbWebSocket}}

    @Test
    func ws() async throws {
        let app = try await buildApplication(reader: reader)
        try await app.test(.live) { client in
            let closeFrame = try await client.ws("/ws") { inbound, outbound, context in
                // write "Hello"
                try await outbound.write(.text("Hello"))
                // read response and verify its contents
                var inboundIterator = inbound.messages(maxSize: .max).makeAsyncIterator()
                let message = try await inboundIterator.next()
                #expect(message == .text("Text message, length: 5"))
            }
            #expect(closeFrame?.closeCode == .normalClosure)
        }
    }
{{/hbWebSocket}}
{{/hbLambda}}
{{#hbLambda}}
    @Test
    func hello() async throws {
        let lambda = try await buildLambda(reader: reader)
        try await lambda.test() { client in
            try await client.execute(uri: "/", method: .get) { response in
                #expect(response.body == "Hello!")
            }
        }
    }
{{/hbLambda}}
}
