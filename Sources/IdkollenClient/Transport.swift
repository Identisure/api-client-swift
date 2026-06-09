import Foundation

internal final class Transport {
    private static let userAgent = "idkollen-client-swift/0.1.0"

    private let session: URLSession
    private let baseUrl: String
    private let authHeader: String
    let encoder: JSONEncoder
    let decoder: JSONDecoder

    init(session: URLSession, baseUrl: String, clientId: String, clientSecret: String) {
        self.session = session
        self.baseUrl = baseUrl.hasSuffix("/") ? String(baseUrl.dropLast()) : baseUrl
        let creds = Data("\(clientId):\(clientSecret)".utf8).base64EncodedString()
        self.authHeader = "Basic \(creds)"
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        var req = buildRequest(method: "POST", path: path)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder.encode(body)
        return try await send(req)
    }

    func get<T: Decodable>(_ path: String) async throws -> T {
        let req = buildRequest(method: "GET", path: path)
        return try await send(req)
    }

    func getRaw(_ path: String) async throws -> Data {
        let req = buildRequest(method: "GET", path: path)
        let (data, response) = try await runSession(req)
        try checkStatus(response: response, data: data)
        return data
    }

    func delete(_ path: String) async throws {
        let req = buildRequest(method: "DELETE", path: path)
        let (data, response) = try await runSession(req)
        try checkStatus(response: response, data: data)
    }

    func postMultipart<T: Decodable>(_ path: String, data: Data, filename: String, mimeType: String) async throws -> T {
        let boundary = UUID().uuidString
        var req = buildRequest(method: "POST", path: path)
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        return try await send(req)
    }

    private func buildRequest(method: String, path: String) -> URLRequest {
        var req = URLRequest(url: URL(string: baseUrl + path)!)
        req.httpMethod = method
        req.setValue(authHeader, forHTTPHeaderField: "Authorization")
        req.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return req
    }

    private func send<T: Decodable>(_ req: URLRequest) async throws -> T {
        let (data, response) = try await runSession(req)
        try checkStatus(response: response, data: data)
        if data.isEmpty {
            // Caller asked for T but body is empty. Decode an empty object if T allows it,
            // otherwise this throws — which is the right behaviour for non-optional T.
            return try decoder.decode(T.self, from: Data("{}".utf8))
        }
        return try decoder.decode(T.self, from: data)
    }

    private func runSession(_ req: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: req)
        } catch {
            throw IdkollenError(statusCode: 0, message: error.localizedDescription)
        }
    }

    private func checkStatus(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw IdkollenError(statusCode: 0, message: "Non-HTTP response")
        }
        guard !(200..<300).contains(http.statusCode) else { return }
        let message: String
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let m = json["message"] as? String {
            message = m
        } else {
            message = String(data: data, encoding: .utf8) ?? ""
        }
        throw IdkollenError(statusCode: http.statusCode, message: message)
    }
}
