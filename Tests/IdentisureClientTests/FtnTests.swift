import XCTest
@testable import IdentisureClient

final class FtnTests: XCTestCase {
    var client: IdentisureClient!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        client = IdentisureClientBuilder(clientId: "cid", clientSecret: "sec")
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

        let result = try await client.ftn.auth(FtnAuthRequest())
        guard case .pending(let p) = result else { return XCTFail("expected pending") }
        XCTAssertEqual(p.url, "https://login")
        XCTAssertEqual(p.id, "abc")
    }

    func testAuthUnknownStatus() async throws {
        MockURLProtocol.enqueue(status: 200, json: [
            "status": "SOMETHING_NEW",
            "id": "abc",
        ])

        let result = try await client.ftn.authStatus(id: "abc")
        guard case .unknown(let status) = result else { return XCTFail("expected unknown") }
        XCTAssertEqual(status, "SOMETHING_NEW")
    }

    func testAgeVerificationCompleted() async throws {
        MockURLProtocol.enqueue(status: 200, json: [
            "status": "COMPLETED",
            "id": "age1",
            "ageVerified": true,
        ])

        let result = try await client.ftn.ageVerification(AgeVerificationRequest(minAge: 18))
        guard case .completed(let done) = result else { return XCTFail("expected completed") }
        XCTAssertTrue(done.ageVerified)
    }
}
