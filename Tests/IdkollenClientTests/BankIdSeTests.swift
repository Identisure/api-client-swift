import XCTest
@testable import IdkollenClient

final class BankIdSeTests: XCTestCase {
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
            "autoStartToken": "tok",
        ])

        let result = try await client.bankIdSe.auth(BankIdSeAuthRequest(ssn: "199001011234"))
        guard case .pending(let pending) = result else { return XCTFail("expected pending") }
        XCTAssertEqual(pending.id, "abc")
        XCTAssertEqual(pending.autoStartToken, "tok")

        let body = try JSONSerialization.jsonObject(with: MockURLProtocol.capturedBodies.last!) as! [String: Any]
        XCTAssertEqual(body["ssn"] as? String, "199001011234")
    }

    func testAuthCompleted() async throws {
        MockURLProtocol.enqueue(status: 200, json: [
            "status": "COMPLETED",
            "id": "abc",
            "ssn": "199001011234",
            "name": "Test User",
            "givenName": "Test",
            "surname": "User",
        ])

        let result = try await client.bankIdSe.auth(BankIdSeAuthRequest())
        guard case .completed(let done) = result else { return XCTFail("expected completed") }
        XCTAssertEqual(done.name, "Test User")
    }

    func testAuthFailed() async throws {
        MockURLProtocol.enqueue(status: 200, json: [
            "status": "FAILED",
            "id": "abc",
            "error": "userCancel",
        ])

        let result = try await client.bankIdSe.auth(BankIdSeAuthRequest())
        guard case .failed(let failed) = result else { return XCTFail("expected failed") }
        XCTAssertEqual(failed.error, "userCancel")
    }

    func testPhoneAuthPending() async throws {
        MockURLProtocol.enqueue(status: 200, json: [
            "status": "PENDING",
            "id": "abc",
            "hintCode": "outstandingTransaction",
        ])

        let result = try await client.bankIdSe.phoneAuth(BankIdSePhoneAuthRequest(ssn: "199001011234", callInitiator: "user"))
        guard case .pending = result else { return XCTFail("expected pending") }
    }

    func testVerify() async throws {
        MockURLProtocol.enqueue(status: 200, json: [
            "ssn": "199001011234",
            "name": "Test User",
            "givenName": "Test",
            "surname": "User",
            "age": 34,
            "verifiedAt": "2026-06-08T10:00:00Z",
        ])

        let result = try await client.bankIdSe.verify(BankIdSeVerifyRequest(qrCode: "qr"))
        XCTAssertEqual(result.age, 34)
        XCTAssertEqual(result.name, "Test User")
    }

    func testCancelAuthSendsDelete() async throws {
        MockURLProtocol.enqueue(status: 204, body: Data())
        try await client.bankIdSe.cancelAuth(id: "xyz")
        let req = MockURLProtocol.capturedRequests.last!
        XCTAssertEqual(req.httpMethod, "DELETE")
        XCTAssertEqual(req.url?.path, "/v3/bankid-se/auth/xyz")
    }
}
