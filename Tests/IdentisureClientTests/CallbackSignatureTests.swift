import XCTest

@testable import IdentisureClient

final class CallbackSignatureTests: XCTestCase {
    let secret = "test-secret"
    let body = Data(#"{"id":"abc","status":"COMPLETED"}"#.utf8)
    let signature = "Ag2m3etnW31OP585jvcrvOupK7Vgsrzcq17KxKvkIOs="

    func testValidSignature() {
        XCTAssertTrue(CallbackSignature.verify(body: body, signature: signature, secret: secret))
    }

    func testTamperedBody() {
        XCTAssertFalse(CallbackSignature.verify(body: body + Data(" ".utf8), signature: signature, secret: secret))
    }

    func testMalformedSignature() {
        XCTAssertFalse(CallbackSignature.verify(body: body, signature: "not base64!", secret: secret))
    }
}
