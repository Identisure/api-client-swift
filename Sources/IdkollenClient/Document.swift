import Foundation

public struct DocumentUploadResponse: Decodable {
    public let id: String
    public let hash: String
}

public final class DocumentEndpoint {
    private let transport: Transport
    internal init(_ transport: Transport) { self.transport = transport }

    public func upload(data: Data, filename: String, mimeType: String = "application/pdf") async throws -> DocumentUploadResponse {
        try await transport.postMultipart("/document", data: data, filename: filename, mimeType: mimeType)
    }

    public func download(id: String) async throws -> Data {
        try await transport.getRaw("/document/\(id)")
    }

    public func delete(id: String) async throws {
        try await transport.delete("/document/\(id)")
    }
}
