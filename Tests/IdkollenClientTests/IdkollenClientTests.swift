import XCTest
@testable import IdkollenClient

final class IdkollenClientTests: XCTestCase {

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    func testBuilderProducesClient() {
        let client = IdkollenClientBuilder(clientId: "id", clientSecret: "secret")
            .environment(.staging)
            .build()
        XCTAssertNotNil(client.bankIdSe)
    }

    func testTransportAttachesBasicAuthAndUserAgent() async throws {
        MockURLProtocol.enqueue(status: 200, json: ["ok": true])
        let session = URLSession.mocked()
        let transport = Transport(session: session, baseUrl: "https://example.test", clientId: "cid", clientSecret: "sec")

        struct Reply: Decodable { let ok: Bool }
        let _: Reply = try await transport.get("/v3/ping")

        let req = MockURLProtocol.capturedRequests.last!
        let expected = "Basic " + Data("cid:sec".utf8).base64EncodedString()
        XCTAssertEqual(req.value(forHTTPHeaderField: "Authorization"), expected)
        XCTAssertTrue(req.value(forHTTPHeaderField: "User-Agent")?.contains("idkollen-client-swift/") ?? false)
        XCTAssertEqual(req.url?.absoluteString, "https://example.test/v3/ping")
    }

    func testNon2xxThrowsIdkollenError() async {
        MockURLProtocol.enqueue(status: 400, json: ["message": "bad request"])
        let session = URLSession.mocked()
        let transport = Transport(session: session, baseUrl: "https://x.test", clientId: "a", clientSecret: "b")

        do {
            struct Reply: Decodable {}
            let _: Reply = try await transport.post("/v3/things", body: ["a": 1])
            XCTFail("Expected throw")
        } catch let error as IdkollenError {
            XCTAssertEqual(error.statusCode, 400)
            XCTAssertEqual(error.message, "bad request")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
