import XCTest
@testable import IdkollenClient

final class MitIdTests: XCTestCase {
    var client: IdkollenClient!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        client = IdkollenClientBuilder(clientId: "cid", clientSecret: "sec")
            .baseUrl("https://x.test")
            .urlSession(.mocked())
            .build()
    }

    func testAuthPending() async throws {
        MockURLProtocol.enqueue(status: 200, json: [
            "status": "PENDING",
            "id": "abc",
            "url": "https://login",
            "bindingMessage": "approve this",
        ])

        let result = try await client.mitId.auth(MitIdAuthRequest())
        guard case .pending(let p) = result else { return XCTFail("expected pending") }
        XCTAssertEqual(p.url, "https://login")
    }

    func testSignCompletedWithSignResult() async throws {
        MockURLProtocol.enqueue(status: 200, json: [
            "status": "COMPLETED",
            "id": "abc",
            "ssn": "1234567890",
            "name": "Test User",
            "givenName": "Test",
            "surname": "User",
            "signResult": ["checksum": "abc123"],
        ])

        let result = try await client.mitId.sign(MitIdSignRequest(text: "please sign"))
        if case .completed(let done) = result {
            XCTAssertEqual(done.signResult?.checksum, "abc123")
        } else {
            XCTFail("expected completed")
        }
    }
}
