import XCTest
@testable import IdkollenClient

final class FrejaTests: XCTestCase {
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
            "autoStartToken": "tok123",
            "qrData": "qr",
        ])

        let result = try await client.freja.auth(FrejaAuthRequest())
        guard case .pending(let p) = result else { return XCTFail("expected pending") }
        XCTAssertEqual(p.qrData, "qr")
    }

    func testAuthCompleted() async throws {
        MockURLProtocol.enqueue(status: 200, json: [
            "status": "COMPLETED",
            "id": "abc",
            "ssn": "199001011234",
            "country": "SE",
            "name": "Test User",
            "givenName": "Test",
            "surname": "User",
        ])

        let result = try await client.freja.auth(FrejaAuthRequest())
        guard case .completed(let c) = result else { return XCTFail("expected completed") }
        XCTAssertEqual(c.country, "SE")
    }
}
