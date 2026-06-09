import XCTest
@testable import IdkollenClient

final class BankIdNoTests: XCTestCase {
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

        let result = try await client.bankIdNo.auth(BankIdNoAuthRequest())
        guard case .pending(let p) = result else { return XCTFail("expected pending") }
        XCTAssertEqual(p.url, "https://login")
    }

    func testAuthCompletedWithSignedDocuments() async throws {
        MockURLProtocol.enqueue(status: 200, json: [
            "status": "COMPLETED",
            "id": "abc",
            "ssn": "12345678901",
            "name": "Test User",
            "givenName": "Test",
            "surname": "User",
            "signedDocuments": [
                ["id": "d1", "hash": "h1"],
                ["id": "d2", "hash": "h2"],
            ],
        ])

        let result = try await client.bankIdNo.auth(BankIdNoAuthRequest())
        guard case .completed(let done) = result else { return XCTFail("expected completed") }
        XCTAssertEqual(done.signedDocuments?.count, 2)
        XCTAssertEqual(done.signedDocuments?.first?.id, "d1")
    }
}
