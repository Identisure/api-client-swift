import Foundation

public struct IdkollenError: Error, CustomStringConvertible {
    public let statusCode: Int
    public let message: String

    public init(statusCode: Int, message: String) {
        self.statusCode = statusCode
        self.message = message
    }

    public var description: String { "IdkollenError(\(statusCode)): \(message)" }
}

public struct WaitError: Error, CustomStringConvertible {
    public let timeout: Bool
    public let underlyingError: Error?

    public init(timeout: Bool, underlyingError: Error? = nil) {
        self.timeout = timeout
        self.underlyingError = underlyingError
    }

    public var description: String {
        timeout ? "Poll timed out" : "Poll error: \(underlyingError.map { String(describing: $0) } ?? "")"
    }
}
