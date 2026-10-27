import XCTest
@testable import IdentisureClient

final class IdentisureClientTests: XCTestCase {

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    func testBuilderProducesClient() {
        let client = IdentisureClientBuilder(clientId: "id", clientSecret: "secret")
            .environment(.staging)
            .build()
        XCTAssertNotNil(client.bankIdSe)
    }

    func testTransportAttachesBasicAuthAndUserAgent() async throws {
        MockURLProtocol.enqueue(status: 200, json: ["ok": true])
        let session = URLSession.mocked()
        let transport = Transport(session: session, baseUrl: "https://example.test", clientId: "cid", clientSecret: "sec", timeout: 30)

        struct Reply: Decodable { let ok: Bool }
        let _: Reply = try await transport.get("/v3/ping")

        let req = MockURLProtocol.capturedRequests.last!
        let expected = "Basic " + Data("cid:sec".utf8).base64EncodedString()
        XCTAssertEqual(req.value(forHTTPHeaderField: "Authorization"), expected)
        XCTAssertTrue(req.value(forHTTPHeaderField: "User-Agent")?.contains("identisure-client-swift/") ?? false)
        XCTAssertEqual(req.url?.absoluteString, "https://example.test/v3/ping")
    }

    func testNon2xxThrowsIdentisureError() async {
        MockURLProtocol.enqueue(status: 400, json: ["message": "bad request"])
        let session = URLSession.mocked()
        let transport = Transport(session: session, baseUrl: "https://x.test", clientId: "a", clientSecret: "b", timeout: 30)

        do {
            struct Reply: Decodable {}
            let _: Reply = try await transport.post("/v3/things", body: ["a": 1])
            XCTFail("Expected throw")
        } catch let error as IdentisureError {
            XCTAssertEqual(error.statusCode, 400)
            XCTAssertEqual(error.message, "bad request")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testBuilderTimeoutAppliesToRequests() async throws {
        MockURLProtocol.enqueue(status: 200, json: ["status": "PENDING", "id": "abc", "autoStartToken": "t"])
        let client = IdentisureClientBuilder(clientId: "id", clientSecret: "secret")
            .baseUrl("https://x.test")
            .urlSession(.mocked())
            .timeout(5)
            .build()

        _ = try? await client.ftn.authStatus(id: "abc")

        XCTAssertEqual(MockURLProtocol.capturedRequests.last?.timeoutInterval, 5)
    }
}
