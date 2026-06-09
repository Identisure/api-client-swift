import XCTest
@testable import IdkollenClient

final class DocumentTests: XCTestCase {
    var client: IdkollenClient!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        client = IdkollenClientBuilder(clientId: "cid", clientSecret: "sec")
            .baseUrl("https://x.test")
            .urlSession(.mocked())
            .build()
    }

    func testUpload() async throws {
        MockURLProtocol.enqueue(status: 200, json: ["id": "doc1", "hash": "h1"])

        let pdfData = "PDF-DATA".data(using: .utf8)!
        let response = try await client.document.upload(data: pdfData, filename: "contract.pdf")

        XCTAssertEqual(response.id, "doc1")
        XCTAssertEqual(response.hash, "h1")

        let req = MockURLProtocol.capturedRequests.last!
        let contentType = req.value(forHTTPHeaderField: "Content-Type") ?? ""
        XCTAssertTrue(contentType.hasPrefix("multipart/form-data; boundary="), "Expected multipart content-type, got: \(contentType)")

        let bodyString = String(data: MockURLProtocol.capturedBodies.last!, encoding: .utf8) ?? ""
        XCTAssertTrue(bodyString.contains("filename=\"contract.pdf\""), "Body should contain filename")
        XCTAssertTrue(bodyString.contains("Content-Type: application/pdf"), "Body should contain mime type")
        XCTAssertTrue(bodyString.contains("PDF-DATA"), "Body should contain file data")
    }

    func testDownloadReturnsRawBytes() async throws {
        let expected = Data([0x25, 0x50, 0x44, 0x46]) + "binary".data(using: .utf8)!
        MockURLProtocol.enqueue(status: 200, body: expected)

        let result = try await client.document.download(id: "doc1")
        XCTAssertEqual(result, expected)
    }

    func testDelete() async throws {
        MockURLProtocol.enqueue(status: 204, body: Data())

        try await client.document.delete(id: "doc1")

        let req = MockURLProtocol.capturedRequests.last!
        XCTAssertEqual(req.httpMethod, "DELETE")
        XCTAssertEqual(req.url?.path, "/document/doc1")
    }
}
