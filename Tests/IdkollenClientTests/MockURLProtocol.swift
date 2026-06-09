import Foundation

final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var queue: [(status: Int, body: Data)] = []
    nonisolated(unsafe) static var capturedRequests: [URLRequest] = []
    nonisolated(unsafe) static var capturedBodies: [Data] = []

    static func enqueue(status: Int, body: Data) {
        queue.append((status: status, body: body))
    }

    static func enqueue(status: Int, json: Any) {
        let data = try! JSONSerialization.data(withJSONObject: json)
        queue.append((status: status, body: data))
    }

    static func reset() {
        queue.removeAll()
        capturedRequests.removeAll()
        capturedBodies.removeAll()
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.capturedRequests.append(request)
        // URLProtocol replaces httpBodyStream with httpBody for us in many cases but we read both.
        if let body = request.httpBody {
            Self.capturedBodies.append(body)
        } else if let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var buf = Data()
            let chunk = 4096
            var bytes = [UInt8](repeating: 0, count: chunk)
            while stream.hasBytesAvailable {
                let read = stream.read(&bytes, maxLength: chunk)
                if read <= 0 { break }
                buf.append(bytes, count: read)
            }
            Self.capturedBodies.append(buf)
        } else {
            Self.capturedBodies.append(Data())
        }

        guard !Self.queue.isEmpty else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "MockURLProtocol", code: 0, userInfo: [NSLocalizedDescriptionKey: "No responses queued"]))
            return
        }
        let item = Self.queue.removeFirst()
        let response = HTTPURLResponse(url: request.url!, statusCode: item.status, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: item.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

extension URLSession {
    static func mocked() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}
