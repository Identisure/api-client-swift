import Foundation

// MARK: - Requests

public struct BankIdNoAuthRequest: Encodable {
    public let redirectUrl: String?
    public let requestSsn: Bool?
    public let requestPhone: Bool?
    public let requestEmail: Bool?
    public let requestAddress: Bool?
    public let refId: String?
    public let appCallbackUri: String?

    public init(
        redirectUrl: String? = nil,
        requestSsn: Bool? = nil,
        requestPhone: Bool? = nil,
        requestEmail: Bool? = nil,
        requestAddress: Bool? = nil,
        refId: String? = nil,
        appCallbackUri: String? = nil
    ) {
        self.redirectUrl = redirectUrl
        self.requestSsn = requestSsn
        self.requestPhone = requestPhone
        self.requestEmail = requestEmail
        self.requestAddress = requestAddress
        self.refId = refId
        self.appCallbackUri = appCallbackUri
    }
}

public struct BankIdNoBackchannelAuthRequest: Encodable {
    public let ssn: String
    public let callbackUrl: String?
    public let refId: String?

    public init(ssn: String, callbackUrl: String? = nil, refId: String? = nil) {
        self.ssn = ssn
        self.callbackUrl = callbackUrl
        self.refId = refId
    }
}

public struct BankIdNoSignRequest: Encodable {
    public let redirectUrl: String?
    public let text: String?
    public let documents: [String]?
    public let requestSsn: Bool?
    public let requestPhone: Bool?
    public let requestEmail: Bool?
    public let requestAddress: Bool?
    public let refId: String?

    public init(
        redirectUrl: String? = nil,
        text: String? = nil,
        documents: [String]? = nil,
        requestSsn: Bool? = nil,
        requestPhone: Bool? = nil,
        requestEmail: Bool? = nil,
        requestAddress: Bool? = nil,
        refId: String? = nil
    ) {
        self.redirectUrl = redirectUrl
        self.text = text
        self.documents = documents
        self.requestSsn = requestSsn
        self.requestPhone = requestPhone
        self.requestEmail = requestEmail
        self.requestAddress = requestAddress
        self.refId = refId
    }
}

// MARK: - Helper structs

public struct BankIdNoSignResult: Decodable {
    public let endUser: String
    public let merchant: String
    public let hash: String
}

public struct BankIdNoSignedDocument: Decodable {
    public let id: String
    public let hash: String
}

// MARK: - Status enum + variants

public enum BankIdNoStatus: Decodable {
    case pending(BankIdNoPending)
    case completed(BankIdNoCompleted)
    case failed(BankIdNoFailed)

    private enum DiscriminatorKey: String, CodingKey { case status }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DiscriminatorKey.self)
        let status = try container.decode(String.self, forKey: .status)
        switch status {
        case "PENDING":   self = .pending(try BankIdNoPending(from: decoder))
        case "COMPLETED": self = .completed(try BankIdNoCompleted(from: decoder))
        case "FAILED":    self = .failed(try BankIdNoFailed(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .status, in: container, debugDescription: "Unknown bankid-no status: \(status)")
        }
    }
}

public struct BankIdNoPending: Decodable {
    public let id: String
    public let refId: String?
    public let url: String?
    public let bindingMessage: String?
}

public struct BankIdNoCompleted: Decodable {
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
    public let signResult: BankIdNoSignResult?
    public let signedDocuments: [BankIdNoSignedDocument]?
}

public struct BankIdNoFailed: Decodable {
    public let id: String
    public let refId: String?
    public let error: String
}

// MARK: - Endpoint

public final class BankIdNoEndpoint {
    private let transport: Transport
    internal init(_ transport: Transport) { self.transport = transport }

    public func auth(_ req: BankIdNoAuthRequest) async throws -> BankIdNoStatus {
        try await transport.post("/v3/bankid-no/auth", body: req)
    }

    public func backchannelAuth(_ req: BankIdNoBackchannelAuthRequest) async throws -> BankIdNoStatus {
        try await transport.post("/v3/bankid-no/backchannel/auth", body: req)
    }

    public func sign(_ req: BankIdNoSignRequest) async throws -> BankIdNoStatus {
        try await transport.post("/v3/bankid-no/sign", body: req)
    }

    public func authStatus(id: String) async throws -> BankIdNoStatus {
        try await transport.get("/v3/bankid-no/auth/\(id)")
    }

    public func signStatus(id: String) async throws -> BankIdNoStatus {
        try await transport.get("/v3/bankid-no/sign/\(id)")
    }

    public func cancelAuth(id: String) async throws {
        try await transport.delete("/v3/bankid-no/auth/\(id)")
    }

    public func cancelSign(id: String) async throws {
        try await transport.delete("/v3/bankid-no/sign/\(id)")
    }

    public func waitForAuth(id: String, opts: PollOptions = .init()) async throws -> BankIdNoStatus {
        try await poll({ try await self.authStatus(id: id) }, opts: opts)
    }

    public func ageVerification(_ req: AgeVerificationRequest) async throws -> AgeVerificationStatus {
        try await transport.post("/v3/bankid-no/age-verification", body: req)
    }

    public func ageVerificationStatus(id: String) async throws -> AgeVerificationStatus {
        try await transport.get("/v3/bankid-no/age-verification/\(id)")
    }

    public func cancelAgeVerification(id: String) async throws {
        try await transport.delete("/v3/bankid-no/age-verification/\(id)")
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

    public func waitForSign(id: String, opts: PollOptions = .init()) async throws -> BankIdNoStatus {
        try await poll({ try await self.signStatus(id: id) }, opts: opts)
    }

    private func poll(_ fn: @escaping () async throws -> BankIdNoStatus, opts: PollOptions) async throws -> BankIdNoStatus {
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
