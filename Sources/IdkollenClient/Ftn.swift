import Foundation

// MARK: - Requests

public struct FtnAuthRequest: Encodable {
    public let redirectUrl: String?
    public let requestPhone: Bool?
    public let requestEmail: Bool?
    public let requestAddress: Bool?
    public let refId: String?

    public init(
        redirectUrl: String? = nil,
        requestPhone: Bool? = nil,
        requestEmail: Bool? = nil,
        requestAddress: Bool? = nil,
        refId: String? = nil
    ) {
        self.redirectUrl = redirectUrl
        self.requestPhone = requestPhone
        self.requestEmail = requestEmail
        self.requestAddress = requestAddress
        self.refId = refId
    }
}

// MARK: - Status enum + variants

public enum FtnStatus: Decodable {
    case pending(FtnPending)
    case completed(FtnCompleted)
    case failed(FtnFailed)

    private enum DiscriminatorKey: String, CodingKey { case status }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DiscriminatorKey.self)
        let status = try container.decode(String.self, forKey: .status)
        switch status {
        case "PENDING":   self = .pending(try FtnPending(from: decoder))
        case "COMPLETED": self = .completed(try FtnCompleted(from: decoder))
        case "FAILED":    self = .failed(try FtnFailed(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .status, in: container, debugDescription: "Unknown ftn status: \(status)")
        }
    }
}

public struct FtnPending: Decodable {
    public let id: String
    public let url: String
    public let refId: String?
}

public struct FtnCompleted: Decodable {
    public let id: String
    public let refId: String?
    public let ssn: String
    public let name: String
    public let givenName: String
    public let surname: String
    public let phone: String?
    public let email: String?
    public let address: String?
    public let birthDate: String?
    public let pid: String?
    public let bankId: String?
}

public struct FtnFailed: Decodable {
    public let id: String
    public let refId: String?
    public let error: String
}

// MARK: - Endpoint

public final class FtnEndpoint {
    private let transport: Transport
    internal init(_ transport: Transport) { self.transport = transport }

    public func auth(_ req: FtnAuthRequest) async throws -> FtnStatus {
        try await transport.post("/v3/ftn/auth", body: req)
    }

    public func ageVerification(_ req: AgeVerificationRequest) async throws -> AgeVerificationStatus {
        try await transport.post("/v3/ftn/age-verification", body: req)
    }

    public func authStatus(id: String) async throws -> FtnStatus {
        try await transport.get("/v3/ftn/auth/\(id)")
    }

    public func ageVerificationStatus(id: String) async throws -> AgeVerificationStatus {
        try await transport.get("/v3/ftn/age-verification/\(id)")
    }

    public func cancelAuth(id: String) async throws {
        try await transport.delete("/v3/ftn/auth/\(id)")
    }

    public func cancelAgeVerification(id: String) async throws {
        try await transport.delete("/v3/ftn/age-verification/\(id)")
    }

    public func waitForAuth(id: String, opts: PollOptions = .init()) async throws -> FtnStatus {
        let deadline = Date().addingTimeInterval(opts.timeout)
        while true {
            let status = try await authStatus(id: id)
            if case .pending = status {
                if Date() >= deadline { throw WaitError(timeout: true) }
                try await Task.sleep(nanoseconds: UInt64(opts.interval * 1_000_000_000))
            } else {
                return status
            }
        }
    }

    public func waitForAgeVerification(id: String, opts: PollOptions = .init()) async throws -> AgeVerificationStatus {
        let deadline = Date().addingTimeInterval(opts.timeout)
        while true {
            let status = try await ageVerificationStatus(id: id)
            if case .pending = status {
                if Date() >= deadline { throw WaitError(timeout: true) }
                try await Task.sleep(nanoseconds: UInt64(opts.interval * 1_000_000_000))
            } else {
                return status
            }
        }
    }
}
