import XCTest
@testable import IdkollenClient

final class VippsTests: XCTestCase {
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
        ])

        let result = try await client.vipps.auth(VippsAuthRequest())
        guard case .pending(let p) = result else { return XCTFail("expected pending") }
        XCTAssertEqual(p.url, "https://login")
        XCTAssertEqual(p.id, "abc")
    }

    func testBackchannelAuthSendsPhone() async throws {
        MockURLProtocol.enqueue(status: 200, json: [
            "status": "PENDING",
            "id": "abc",
        ])

        _ = try await client.vipps.backchannelAuth(VippsBackchannelAuthRequest(phone: "+4712345678"))

        let body = try JSONSerialization.jsonObject(with: MockURLProtocol.capturedBodies.last!) as! [String: Any]
        XCTAssertEqual(body["phone"] as? String, "+4712345678")
    }
}
