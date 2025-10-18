import Hummingbird
{{^hbLambda}}
import HummingbirdTesting
{{/hbLambda}}
{{#hbLambda}}
import HummingbirdLambdaTesting
{{/hbLambda}}
import Logging
import XCTest

@testable import {{hbExecutableName}}

final class AppTests: XCTestCase {
{{^hbLambda}}
    struct TestArguments: AppArguments {
        let hostname = "127.0.0.1"
        let port = 0
        let logLevel: Logger.Level? = .trace
    }
{{/hbLambda}}

{{^hbLambda}}
    func testApp() async throws {
        let args = TestArguments()
        let app = try await buildApplication(args)
        try await app.test(.router) { client in
            try await client.execute(uri: "/", method: .get) { response in
                XCTAssertEqual(response.body, ByteBuffer(string: "Hello!"))
            }
        }
    }
{{/hbLambda}}
{{#hbLambda}}
    func testLambda() async throws {
        let lambda = try await buildLambda()
        try await lambda.test() { client in
            try await client.execute(uri: "/", method: .get) { response in
                XCTAssertEqual(response.body, "Hello!")
            }
        }
    }
{{/hbLambda}}
}
