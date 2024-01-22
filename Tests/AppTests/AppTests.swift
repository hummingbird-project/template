@testable import App
import Hummingbird
import HummingbirdXCT
import XCTest

final class AppTests: XCTestCase {
    struct TestArguments: AppArguments {
        let hostname = "127.0.0.1"
        let port = 0
    }

    func testApp() async throws {
        let args = TestArguments()
        let app = buildApplication(args)
        try await app.test(.router) { client in
            try await client.XCTExecute(uri: "/health", method: .get) { response in
                XCTAssertEqual(response.status, .ok)
            }
        }
    }
}
