import Foundation

public struct DocumentUploadResponse: Decodable {
    public let id: String
    public let hash: String
}

public final class DocumentEndpoint {
    private let transport: Transport
    internal init(_ transport: Transport) { self.transport = transport }

    public func upload(data: Data, filename: String, mimeType: String = "application/pdf") async throws -> DocumentUploadResponse {
        try await transport.postMultipart("/v3/document", data: data, filename: filename, mimeType: mimeType)
    }

    public func download(id: String) async throws -> Data {
        try await transport.getRaw("/v3/document/\(id)")
    }
}
