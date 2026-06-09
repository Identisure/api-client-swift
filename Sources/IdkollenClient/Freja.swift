import Foundation

// MARK: - Requests

public struct FrejaAuthRequest: Encodable {
    public let ssn: String?
    public let callbackUrl: String?
    public let minRegistrationLevel: String?
    public let orgNumber: String?
    public let requestAddress: Bool?
    public let refId: String?

    public init(
        ssn: String? = nil,
        callbackUrl: String? = nil,
        minRegistrationLevel: String? = nil,
        orgNumber: String? = nil,
        requestAddress: Bool? = nil,
        refId: String? = nil
    ) {
        self.ssn = ssn
        self.callbackUrl = callbackUrl
        self.minRegistrationLevel = minRegistrationLevel
        self.orgNumber = orgNumber
        self.requestAddress = requestAddress
        self.refId = refId
    }
}

public struct FrejaBackchannelAuthRequest: Encodable {
    public let ssn: String
    public let country: String
    public let callbackUrl: String?
    public let minRegistrationLevel: String?
    public let orgNumber: String?
    public let requestAddress: Bool?
    public let refId: String?

    public init(
        ssn: String,
        country: String,
        callbackUrl: String? = nil,
        minRegistrationLevel: String? = nil,
        orgNumber: String? = nil,
        requestAddress: Bool? = nil,
        refId: String? = nil
    ) {
        self.ssn = ssn
        self.country = country
        self.callbackUrl = callbackUrl
        self.minRegistrationLevel = minRegistrationLevel
        self.orgNumber = orgNumber
        self.requestAddress = requestAddress
        self.refId = refId
    }
}

public struct FrejaSignRequest: Encodable {
    public let text: String
    public let ssn: String?
    public let callbackUrl: String?
    public let minRegistrationLevel: String?
    public let orgNumber: String?
    public let requestAddress: Bool?
    public let refId: String?

    public init(
        text: String,
        ssn: String? = nil,
        callbackUrl: String? = nil,
        minRegistrationLevel: String? = nil,
        orgNumber: String? = nil,
        requestAddress: Bool? = nil,
        refId: String? = nil
    ) {
        self.text = text
        self.ssn = ssn
        self.callbackUrl = callbackUrl
        self.minRegistrationLevel = minRegistrationLevel
        self.orgNumber = orgNumber
        self.requestAddress = requestAddress
        self.refId = refId
    }
}

public struct FrejaBackchannelSignRequest: Encodable {
    public let ssn: String
    public let country: String
    public let text: String
    public let callbackUrl: String?
    public let minRegistrationLevel: String?
    public let orgNumber: String?
    public let requestAddress: Bool?
    public let refId: String?

    public init(
        ssn: String,
        country: String,
        text: String,
        callbackUrl: String? = nil,
        minRegistrationLevel: String? = nil,
        orgNumber: String? = nil,
        requestAddress: Bool? = nil,
        refId: String? = nil
    ) {
        self.ssn = ssn
        self.country = country
        self.text = text
        self.callbackUrl = callbackUrl
        self.minRegistrationLevel = minRegistrationLevel
        self.orgNumber = orgNumber
        self.requestAddress = requestAddress
        self.refId = refId
    }
}

// MARK: - Status enum + variants

public enum FrejaStatus: Decodable {
    case pending(FrejaPending)
    case completed(FrejaCompleted)
    case failed(FrejaFailed)

    private enum DiscriminatorKey: String, CodingKey { case status }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DiscriminatorKey.self)
        let status = try container.decode(String.self, forKey: .status)
        switch status {
        case "PENDING":   self = .pending(try FrejaPending(from: decoder))
        case "COMPLETED": self = .completed(try FrejaCompleted(from: decoder))
        case "FAILED":    self = .failed(try FrejaFailed(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .status, in: container, debugDescription: "Unknown freja status: \(status)")
        }
    }
}

public struct FrejaPending: Decodable {
    public let id: String
    public let refId: String?
    public let autoStartToken: String
    public let qrData: String
}

public struct FrejaCompleted: Decodable {
    public let id: String
    public let refId: String?
    public let ssn: String
    public let country: String
    public let name: String
    public let givenName: String
    public let surname: String
    public let address: String?
    public let companySignatoryText: String?
}

public struct FrejaFailed: Decodable {
    public let id: String
    public let refId: String?
    public let error: String
}

// MARK: - Endpoint

public final class FrejaEndpoint {
    private let transport: Transport
    internal init(_ transport: Transport) { self.transport = transport }

    public func auth(_ req: FrejaAuthRequest) async throws -> FrejaStatus {
        try await transport.post("/v3/freja/auth", body: req)
    }

    public func backchannelAuth(_ req: FrejaBackchannelAuthRequest) async throws -> FrejaStatus {
        try await transport.post("/v3/freja/backchannel/auth", body: req)
    }

    public func sign(_ req: FrejaSignRequest) async throws -> FrejaStatus {
        try await transport.post("/v3/freja/sign", body: req)
    }

    public func backchannelSign(_ req: FrejaBackchannelSignRequest) async throws -> FrejaStatus {
        try await transport.post("/v3/freja/backchannel/sign", body: req)
    }

    public func authStatus(id: String) async throws -> FrejaStatus {
        try await transport.get("/v3/freja/auth/\(id)")
    }

    public func signStatus(id: String) async throws -> FrejaStatus {
        try await transport.get("/v3/freja/sign/\(id)")
    }

    public func cancelAuth(id: String) async throws {
        try await transport.delete("/v3/freja/auth/\(id)")
    }

    public func cancelSign(id: String) async throws {
        try await transport.delete("/v3/freja/sign/\(id)")
    }

    public func waitForAuth(id: String, opts: PollOptions = .init()) async throws -> FrejaStatus {
        try await poll({ try await self.authStatus(id: id) }, opts: opts)
    }

    public func ageVerification(_ req: AgeVerificationRequest) async throws -> AgeVerificationStatus {
        try await transport.post("/v3/freja/age-verification", body: req)
    }

    public func ageVerificationStatus(id: String) async throws -> AgeVerificationStatus {
        try await transport.get("/v3/freja/age-verification/\(id)")
    }

    public func cancelAgeVerification(id: String) async throws {
        try await transport.delete("/v3/freja/age-verification/\(id)")
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

    public func waitForSign(id: String, opts: PollOptions = .init()) async throws -> FrejaStatus {
        try await poll({ try await self.signStatus(id: id) }, opts: opts)
    }

    private func poll(_ fn: @escaping () async throws -> FrejaStatus, opts: PollOptions) async throws -> FrejaStatus {
        let deadline = Date().addingTimeInterval(opts.timeout)
        while true {
            let status = try await fn()
            if case .pending = status {
                if Date() >= deadline { throw WaitError(timeout: true) }
                try await Task.sleep(nanoseconds: UInt64(opts.interval * 1_000_000_000))
            } else {
                return status
            }
        }
    }
}
