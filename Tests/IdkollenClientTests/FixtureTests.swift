import XCTest
@testable import IdkollenClient

final class FixtureTests: XCTestCase {
    private static let fixturesDir = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("fixtures")

    private let fastPoll = PollOptions(interval: 0.001)
    var client: IdkollenClient!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        client = IdkollenClientBuilder(clientId: "cid", clientSecret: "sec")
            .baseUrl("https://x.test")
            .urlSession(.mocked())
            .build()
    }

    // MARK: - Auth

    func testBankIdSeAuth() async throws {
        let id = try enqueueFlow("bankid_se/auth_pending.json", "bankid_se/auth_completed.json")

        guard case .pending(let pending) = try await client.bankIdSe.auth(BankIdSeAuthRequest()) else { return XCTFail("expected pending") }
        let p = try json("bankid_se/auth_pending.json")
        XCTAssertEqual(pending.id, id)
        XCTAssertEqual(pending.autoStartToken, p["autoStartToken"] as? String)
        XCTAssertEqual(pending.qrStartToken, p["qrStartToken"] as? String)
        XCTAssertEqual(pending.qrStartSecret, p["qrStartSecret"] as? String)
        XCTAssertEqual(pending.hintCode, p["hintCode"] as? String)

        guard case .completed(let done) = try await client.bankIdSe.waitForAuth(id: id, opts: fastPoll) else { return XCTFail("expected completed") }
        try assertBankIdSeCompleted(done, "bankid_se/auth_completed.json")
        assertRequests(authFlow("bankid-se", id))
    }

    func testBankIdNoAuth() async throws {
        let id = try enqueueFlow("bankid_no/auth_pending.json", "bankid_no/auth_completed.json")

        guard case .pending(let pending) = try await client.bankIdNo.auth(BankIdNoAuthRequest()) else { return XCTFail("expected pending") }
        let p = try json("bankid_no/auth_pending.json")
        XCTAssertEqual(pending.id, id)
        XCTAssertEqual(pending.url, p["url"] as? String)
        XCTAssertEqual(pending.bindingMessage, p["bindingMessage"] as? String)

        guard case .completed(let done) = try await client.bankIdNo.waitForAuth(id: id, opts: fastPoll) else { return XCTFail("expected completed") }
        let f = try json("bankid_no/auth_completed.json")
        assertPerson(id: done.id, refId: done.refId, ssn: done.ssn, name: done.name, givenName: done.givenName, surname: done.surname, f)
        assertContact(phone: done.phone, email: done.email, address: done.address, birthDate: done.birthDate, pid: done.pid, bankId: done.bankId, f)
        XCTAssertEqual(done.authenticatedAt, f["authenticatedAt"] as? String)
        assertRequests(authFlow("bankid-no", id))
    }

    func testFrejaAuth() async throws {
        let id = try enqueueFlow("freja/auth_pending.json", "freja/auth_completed.json")

        guard case .pending(let pending) = try await client.freja.auth(FrejaAuthRequest()) else { return XCTFail("expected pending") }
        let p = try json("freja/auth_pending.json")
        XCTAssertEqual(pending.id, id)
        XCTAssertEqual(pending.autoStartToken, p["autoStartToken"] as? String)
        XCTAssertEqual(pending.qrData, p["qrData"] as? String)

        guard case .completed(let done) = try await client.freja.waitForAuth(id: id, opts: fastPoll) else { return XCTFail("expected completed") }
        try assertFrejaCompleted(done, "freja/auth_completed.json")
        assertRequests(authFlow("freja", id))
    }

    func testMitIdAuth() async throws {
        let id = try enqueueFlow("mitid/auth_pending.json", "mitid/auth_completed.json")

        guard case .pending(let pending) = try await client.mitId.auth(MitIdAuthRequest()) else { return XCTFail("expected pending") }
        XCTAssertEqual(pending.id, id)
        XCTAssertEqual(pending.url, try json("mitid/auth_pending.json")["url"] as? String)

        guard case .completed(let done) = try await client.mitId.waitForAuth(id: id, opts: fastPoll) else { return XCTFail("expected completed") }
        let f = try json("mitid/auth_completed.json")
        assertPerson(id: done.id, refId: done.refId, ssn: done.ssn, name: done.name, givenName: done.givenName, surname: done.surname, f)
        assertContact(phone: done.phone, email: done.email, address: done.address, birthDate: done.birthDate, pid: done.pid, bankId: done.bankId, f)
        XCTAssertEqual(done.authenticatedAt, f["authenticatedAt"] as? String)
        assertRequests(authFlow("mitid", id))
    }

    func testFtnAuth() async throws {
        let id = try enqueueFlow("ftn/auth_pending.json", "ftn/auth_completed.json")

        guard case .pending(let pending) = try await client.ftn.auth(FtnAuthRequest()) else { return XCTFail("expected pending") }
        XCTAssertEqual(pending.id, id)
        XCTAssertEqual(pending.url, try json("ftn/auth_pending.json")["url"] as? String)

        guard case .completed(let done) = try await client.ftn.waitForAuth(id: id, opts: fastPoll) else { return XCTFail("expected completed") }
        let f = try json("ftn/auth_completed.json")
        assertPerson(id: done.id, refId: done.refId, ssn: done.ssn, name: done.name, givenName: done.givenName, surname: done.surname, f)
        assertContact(phone: done.phone, email: done.email, address: done.address, birthDate: done.birthDate, pid: done.pid, bankId: done.bankId, f)
        XCTAssertEqual(done.bankName, f["bankName"] as? String)
        XCTAssertEqual(done.authenticatedAt, f["authenticatedAt"] as? String)
        assertRequests(authFlow("ftn", id))
    }

    func testVippsAuth() async throws {
        let id = try enqueueFlow("vipps/auth_pending.json", "vipps/auth_completed.json")

        guard case .pending(let pending) = try await client.vipps.auth(VippsAuthRequest()) else { return XCTFail("expected pending") }
        XCTAssertEqual(pending.id, id)
        XCTAssertEqual(pending.url, try json("vipps/auth_pending.json")["url"] as? String)

        guard case .completed(let done) = try await client.vipps.waitForAuth(id: id, opts: fastPoll) else { return XCTFail("expected completed") }
        let f = try json("vipps/auth_completed.json")
        assertPerson(id: done.id, refId: done.refId, ssn: done.ssn, name: done.name, givenName: done.givenName, surname: done.surname, f)
        assertContact(phone: done.phone, email: done.email, address: done.address, birthDate: done.birthDate, pid: done.pid, bankId: done.bankId, f)
        XCTAssertEqual(done.authenticatedAt, f["authenticatedAt"] as? String)
        assertRequests(authFlow("vipps", id))
    }

    // MARK: - Failed and unknown

    func testBankIdSeFailedAndUnknown() async throws {
        var id = try enqueueTerminal("bankid_se/auth_pending.json", "bankid_se/auth_failed.json")
        _ = try await client.bankIdSe.auth(BankIdSeAuthRequest())
        guard case .failed(let failed) = try await client.bankIdSe.waitForAuth(id: id, opts: fastPoll) else { return XCTFail("expected failed") }
        try assertFailed(id: failed.id, error: failed.error, "bankid_se/auth_failed.json")

        id = try enqueueTerminal("bankid_se/auth_pending.json", "bankid_se/auth_unknown.json")
        _ = try await client.bankIdSe.auth(BankIdSeAuthRequest())
        guard case .unknown(let status) = try await client.bankIdSe.waitForAuth(id: id, opts: fastPoll) else { return XCTFail("expected unknown") }
        XCTAssertEqual(status, "SOMETHING_NEW")
    }

    func testBankIdNoFailedAndUnknown() async throws {
        var id = try enqueueTerminal("bankid_no/auth_pending.json", "bankid_no/auth_failed.json")
        _ = try await client.bankIdNo.auth(BankIdNoAuthRequest())
        guard case .failed(let failed) = try await client.bankIdNo.waitForAuth(id: id, opts: fastPoll) else { return XCTFail("expected failed") }
        try assertFailed(id: failed.id, error: failed.error, "bankid_no/auth_failed.json")

        id = try enqueueTerminal("bankid_no/auth_pending.json", "bankid_no/auth_unknown.json")
        _ = try await client.bankIdNo.auth(BankIdNoAuthRequest())
        guard case .unknown(let status) = try await client.bankIdNo.waitForAuth(id: id, opts: fastPoll) else { return XCTFail("expected unknown") }
        XCTAssertEqual(status, "SOMETHING_NEW")
    }

    func testFrejaFailedAndUnknown() async throws {
        var id = try enqueueTerminal("freja/auth_pending.json", "freja/auth_failed.json")
        _ = try await client.freja.auth(FrejaAuthRequest())
        guard case .failed(let failed) = try await client.freja.waitForAuth(id: id, opts: fastPoll) else { return XCTFail("expected failed") }
        try assertFailed(id: failed.id, error: failed.error, "freja/auth_failed.json")

        id = try enqueueTerminal("freja/auth_pending.json", "freja/auth_unknown.json")
        _ = try await client.freja.auth(FrejaAuthRequest())
        guard case .unknown(let status) = try await client.freja.waitForAuth(id: id, opts: fastPoll) else { return XCTFail("expected unknown") }
        XCTAssertEqual(status, "SOMETHING_NEW")
    }

    func testMitIdFailedAndUnknown() async throws {
        var id = try enqueueTerminal("mitid/auth_pending.json", "mitid/auth_failed.json")
        _ = try await client.mitId.auth(MitIdAuthRequest())
        guard case .failed(let failed) = try await client.mitId.waitForAuth(id: id, opts: fastPoll) else { return XCTFail("expected failed") }
        try assertFailed(id: failed.id, error: failed.error, "mitid/auth_failed.json")

        id = try enqueueTerminal("mitid/auth_pending.json", "mitid/auth_unknown.json")
        _ = try await client.mitId.auth(MitIdAuthRequest())
        guard case .unknown(let status) = try await client.mitId.waitForAuth(id: id, opts: fastPoll) else { return XCTFail("expected unknown") }
        XCTAssertEqual(status, "SOMETHING_NEW")
    }

    func testFtnFailedAndUnknown() async throws {
        var id = try enqueueTerminal("ftn/auth_pending.json", "ftn/auth_failed.json")
        _ = try await client.ftn.auth(FtnAuthRequest())
        guard case .failed(let failed) = try await client.ftn.waitForAuth(id: id, opts: fastPoll) else { return XCTFail("expected failed") }
        try assertFailed(id: failed.id, error: failed.error, "ftn/auth_failed.json")

        id = try enqueueTerminal("ftn/auth_pending.json", "ftn/auth_unknown.json")
        _ = try await client.ftn.auth(FtnAuthRequest())
        guard case .unknown(let status) = try await client.ftn.waitForAuth(id: id, opts: fastPoll) else { return XCTFail("expected unknown") }
        XCTAssertEqual(status, "SOMETHING_NEW")
    }

    func testVippsFailedAndUnknown() async throws {
        var id = try enqueueTerminal("vipps/auth_pending.json", "vipps/auth_failed.json")
        _ = try await client.vipps.auth(VippsAuthRequest())
        guard case .failed(let failed) = try await client.vipps.waitForAuth(id: id, opts: fastPoll) else { return XCTFail("expected failed") }
        try assertFailed(id: failed.id, error: failed.error, "vipps/auth_failed.json")

        id = try enqueueTerminal("vipps/auth_pending.json", "vipps/auth_unknown.json")
        _ = try await client.vipps.auth(VippsAuthRequest())
        guard case .unknown(let status) = try await client.vipps.waitForAuth(id: id, opts: fastPoll) else { return XCTFail("expected unknown") }
        XCTAssertEqual(status, "SOMETHING_NEW")
    }

    // MARK: - Sign

    func testBankIdSeSign() async throws {
        let id = try enqueueFlow("bankid_se/auth_pending.json", "bankid_se/sign_completed.json")

        guard case .pending = try await client.bankIdSe.sign(BankIdSeSignRequest(text: "Sign this")) else { return XCTFail("expected pending") }
        guard case .completed(let done) = try await client.bankIdSe.waitForSign(id: id, opts: fastPoll) else { return XCTFail("expected completed") }
        try assertBankIdSeCompleted(done, "bankid_se/sign_completed.json")
        assertRequests(signFlow("bankid-se", id))
    }

    func testBankIdNoSign() async throws {
        let id = try enqueueFlow("bankid_no/auth_pending.json", "bankid_no/sign_completed.json")

        guard case .pending = try await client.bankIdNo.sign(BankIdNoSignRequest(text: "Sign this")) else { return XCTFail("expected pending") }
        guard case .completed(let done) = try await client.bankIdNo.waitForSign(id: id, opts: fastPoll) else { return XCTFail("expected completed") }
        let f = try json("bankid_no/sign_completed.json")
        assertPerson(id: done.id, refId: done.refId, ssn: done.ssn, name: done.name, givenName: done.givenName, surname: done.surname, f)
        XCTAssertEqual(done.signedAt, f["signedAt"] as? String)
        let signResult = try XCTUnwrap(f["signResult"] as? [String: Any])
        XCTAssertEqual(done.signResult?.hash, signResult["hash"] as? String)
        XCTAssertEqual(done.signResult?.endUser, signResult["endUser"] as? String)
        XCTAssertEqual(done.signResult?.merchant, signResult["merchant"] as? String)
        let docs = try XCTUnwrap(f["signedDocuments"] as? [[String: Any]])
        XCTAssertEqual(done.signedDocuments?.count, docs.count)
        XCTAssertEqual(done.signedDocuments?.first?.id, docs.first?["id"] as? String)
        XCTAssertEqual(done.signedDocuments?.first?.hash, docs.first?["hash"] as? String)
        assertRequests(signFlow("bankid-no", id))
    }

    func testFrejaSign() async throws {
        let id = try enqueueFlow("freja/auth_pending.json", "freja/sign_completed.json")

        guard case .pending = try await client.freja.sign(FrejaSignRequest(text: "Sign this")) else { return XCTFail("expected pending") }
        guard case .completed(let done) = try await client.freja.waitForSign(id: id, opts: fastPoll) else { return XCTFail("expected completed") }
        try assertFrejaCompleted(done, "freja/sign_completed.json")
        assertRequests(signFlow("freja", id))
    }

    func testMitIdSign() async throws {
        let id = try enqueueFlow("mitid/auth_pending.json", "mitid/sign_completed.json")

        guard case .pending = try await client.mitId.sign(MitIdSignRequest(text: "Sign this")) else { return XCTFail("expected pending") }
        guard case .completed(let done) = try await client.mitId.waitForSign(id: id, opts: fastPoll) else { return XCTFail("expected completed") }
        let f = try json("mitid/sign_completed.json")
        assertPerson(id: done.id, refId: done.refId, ssn: done.ssn, name: done.name, givenName: done.givenName, surname: done.surname, f)
        XCTAssertEqual(done.signedAt, f["signedAt"] as? String)
        let signResult = try XCTUnwrap(f["signResult"] as? [String: Any])
        XCTAssertEqual(done.signResult?.checksum, signResult["checksum"] as? String)
        assertRequests(signFlow("mitid", id))
    }

    // MARK: - BankID SE extras

    func testBankIdSePhoneAuth() async throws {
        let id = try json("bankid_se/phone_auth_pending.json")["id"] as! String
        MockURLProtocol.enqueue(status: 201, body: try fixture("bankid_se/phone_auth_pending.json"))
        MockURLProtocol.enqueue(status: 200, body: try fixture("bankid_se/auth_completed.json"))

        let started = try await client.bankIdSe.phoneAuth(BankIdSePhoneAuthRequest(ssn: "199001011239", callInitiator: "USER"))
        guard case .pending(let pending) = started else { return XCTFail("expected pending") }
        XCTAssertEqual(pending.id, id)
        XCTAssertNil(pending.hintCode)

        guard case .completed(let done) = try await client.bankIdSe.waitForAuth(id: id, opts: fastPoll) else { return XCTFail("expected completed") }
        try assertBankIdSeCompleted(done, "bankid_se/auth_completed.json")
        assertRequests([("POST", "/v3/bankid-se/phone/auth"), ("GET", "/v3/bankid-se/auth/\(id)")])
    }

    func testBankIdSeVerify() async throws {
        MockURLProtocol.enqueue(status: 200, body: try fixture("bankid_se/verify.json"))

        let result = try await client.bankIdSe.verify(BankIdSeVerifyRequest(qrCode: "bankidqr.1.2.3"))

        let f = try json("bankid_se/verify.json")
        XCTAssertEqual(result.ssn, f["ssn"] as? String)
        XCTAssertEqual(result.name, f["name"] as? String)
        XCTAssertEqual(result.givenName, f["givenName"] as? String)
        XCTAssertEqual(result.surname, f["surname"] as? String)
        XCTAssertEqual(result.age, f["age"] as? Int)
        XCTAssertEqual(result.verifiedAt, f["verifiedAt"] as? String)
        assertRequests([("POST", "/v3/bankid-se/verify")])
    }

    // MARK: - Age verification

    func testAgeVerification() async throws {
        let id = try enqueueFlow("age_verification/pending.json", "age_verification/completed.json")

        guard case .pending(let pending) = try await client.bankIdSe.ageVerification(AgeVerificationRequest(minAge: 18)) else { return XCTFail("expected pending") }
        let p = try json("age_verification/pending.json")
        XCTAssertEqual(pending.id, id)
        XCTAssertEqual(pending.url, p["url"] as? String)
        XCTAssertEqual(pending.minAge, p["minAge"] as? Int)
        XCTAssertNil(pending.maxAge)

        guard case .completed(let done) = try await client.bankIdSe.waitForAgeVerification(id: id, opts: fastPoll) else { return XCTFail("expected completed") }
        XCTAssertEqual(done.id, id)
        XCTAssertEqual(done.ageVerified, try json("age_verification/completed.json")["ageVerified"] as? Bool)
        assertRequests([
            ("POST", "/v3/bankid-se/age-verification"),
            ("GET", "/v3/bankid-se/age-verification/\(id)"),
            ("GET", "/v3/bankid-se/age-verification/\(id)"),
        ])
    }

    func testAgeVerificationFailedAndUnknown() async throws {
        var id = try enqueueTerminal("age_verification/pending.json", "age_verification/failed.json")
        _ = try await client.bankIdSe.ageVerification(AgeVerificationRequest(minAge: 18))
        guard case .failed(let failed) = try await client.bankIdSe.waitForAgeVerification(id: id, opts: fastPoll) else { return XCTFail("expected failed") }
        try assertFailed(id: failed.id, error: failed.error, "age_verification/failed.json")

        id = try enqueueTerminal("age_verification/pending.json", "age_verification/unknown.json")
        _ = try await client.bankIdSe.ageVerification(AgeVerificationRequest(minAge: 18))
        guard case .unknown(let status) = try await client.bankIdSe.waitForAgeVerification(id: id, opts: fastPoll) else { return XCTFail("expected unknown") }
        XCTAssertEqual(status, "SOMETHING_NEW")
    }

    // MARK: - Document and errors

    func testDocumentUpload() async throws {
        MockURLProtocol.enqueue(status: 201, body: try fixture("document/upload.json"))

        let result = try await client.document.upload(data: Data("%PDF-1.7".utf8), filename: "contract.pdf")

        let f = try json("document/upload.json")
        XCTAssertEqual(result.id, f["id"] as? String)
        XCTAssertEqual(result.hash, f["hash"] as? String)
        assertRequests([("POST", "/v3/document")])
    }

    func testErrorResponse() async throws {
        MockURLProtocol.enqueue(status: 400, body: try fixture("error.json"))

        do {
            _ = try await client.ftn.auth(FtnAuthRequest())
            XCTFail("Expected throw")
        } catch let error as IdkollenError {
            XCTAssertEqual(error.statusCode, 400)
            XCTAssertTrue(error.message.contains("Invalid request"))
        }
    }

    // MARK: - Helpers

    private func fixture(_ path: String) throws -> Data {
        try Data(contentsOf: Self.fixturesDir.appendingPathComponent(path))
    }

    private func json(_ path: String) throws -> [String: Any] {
        try XCTUnwrap(try JSONSerialization.jsonObject(with: try fixture(path)) as? [String: Any])
    }

    /// Queues start (201), one pending poll and the terminal poll. Returns the session id.
    private func enqueueFlow(_ pending: String, _ terminal: String) throws -> String {
        MockURLProtocol.enqueue(status: 201, body: try fixture(pending))
        MockURLProtocol.enqueue(status: 200, body: try fixture(pending))
        MockURLProtocol.enqueue(status: 200, body: try fixture(terminal))
        return try XCTUnwrap(try json(pending)["id"] as? String)
    }

    /// Queues start (201) and the terminal poll. Returns the session id.
    private func enqueueTerminal(_ pending: String, _ terminal: String) throws -> String {
        MockURLProtocol.enqueue(status: 201, body: try fixture(pending))
        MockURLProtocol.enqueue(status: 200, body: try fixture(terminal))
        return try XCTUnwrap(try json(pending)["id"] as? String)
    }

    private func authFlow(_ segment: String, _ id: String) -> [(String, String)] {
        [("POST", "/v3/\(segment)/auth"), ("GET", "/v3/\(segment)/auth/\(id)"), ("GET", "/v3/\(segment)/auth/\(id)")]
    }

    private func signFlow(_ segment: String, _ id: String) -> [(String, String)] {
        [("POST", "/v3/\(segment)/sign"), ("GET", "/v3/\(segment)/sign/\(id)"), ("GET", "/v3/\(segment)/sign/\(id)")]
    }

    private func assertRequests(_ expected: [(String, String)], file: StaticString = #filePath, line: UInt = #line) {
        let requests = MockURLProtocol.capturedRequests
        XCTAssertEqual(requests.map { $0.httpMethod ?? "" }, expected.map { $0.0 }, file: file, line: line)
        XCTAssertEqual(requests.map { $0.url?.path ?? "" }, expected.map { $0.1 }, file: file, line: line)
        let auth = "Basic " + Data("cid:sec".utf8).base64EncodedString()
        for request in requests {
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), auth, file: file, line: line)
        }
    }

    private func assertPerson(id: String, refId: String?, ssn: String?, name: String, givenName: String, surname: String, _ f: [String: Any], file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(id, f["id"] as? String, file: file, line: line)
        XCTAssertEqual(refId, f["refId"] as? String, file: file, line: line)
        XCTAssertEqual(ssn, f["ssn"] as? String, file: file, line: line)
        XCTAssertEqual(name, f["name"] as? String, file: file, line: line)
        XCTAssertEqual(givenName, f["givenName"] as? String, file: file, line: line)
        XCTAssertEqual(surname, f["surname"] as? String, file: file, line: line)
    }

    private func assertContact(phone: String?, email: String?, address: String?, birthDate: String?, pid: String?, bankId: String?, _ f: [String: Any], file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(phone, f["phone"] as? String, file: file, line: line)
        XCTAssertEqual(email, f["email"] as? String, file: file, line: line)
        XCTAssertEqual(address, f["address"] as? String, file: file, line: line)
        XCTAssertEqual(birthDate, f["birthDate"] as? String, file: file, line: line)
        XCTAssertEqual(pid, f["pid"] as? String, file: file, line: line)
        XCTAssertEqual(bankId, f["bankId"] as? String, file: file, line: line)
    }

    private func assertFailed(id: String, error: String, _ path: String, file: StaticString = #filePath, line: UInt = #line) throws {
        let f = try json(path)
        XCTAssertEqual(id, f["id"] as? String, file: file, line: line)
        XCTAssertEqual(error, f["error"] as? String, file: file, line: line)
    }

    private func assertBankIdSeCompleted(_ done: BankIdSeCompleted, _ path: String) throws {
        let f = try json(path)
        assertPerson(id: done.id, refId: done.refId, ssn: done.ssn, name: done.name, givenName: done.givenName, surname: done.surname, f)
        XCTAssertEqual(done.certStartDate, f["certStartDate"] as? String)
        XCTAssertEqual(done.ocspResponse, f["ocspResponse"] as? String)
        XCTAssertEqual(done.risk, f["risk"] as? String)
        XCTAssertEqual(done.address, f["address"] as? String)
        XCTAssertEqual(done.authenticatedAt, f["authenticatedAt"] as? String)
        XCTAssertEqual(done.signedAt, f["signedAt"] as? String)
        let device = try XCTUnwrap(f["device"] as? [String: Any])
        XCTAssertEqual(done.device?.ipAddress, device["ipAddress"] as? String)
        XCTAssertEqual(done.device?.uhi, device["uhi"] as? String)
        let stepUp = try XCTUnwrap(f["stepUp"] as? [String: Any])
        XCTAssertEqual(done.stepUp?.mrtd, stepUp["mrtd"] as? Bool)
        XCTAssertEqual(done.stepUp?.face, stepUp["face"] as? Bool)
    }

    private func assertFrejaCompleted(_ done: FrejaCompleted, _ path: String) throws {
        let f = try json(path)
        assertPerson(id: done.id, refId: done.refId, ssn: done.ssn, name: done.name, givenName: done.givenName, surname: done.surname, f)
        XCTAssertEqual(done.country, f["country"] as? String)
        XCTAssertEqual(done.address, f["address"] as? String)
        XCTAssertEqual(done.authenticatedAt, f["authenticatedAt"] as? String)
        XCTAssertEqual(done.signedAt, f["signedAt"] as? String)
    }
}
