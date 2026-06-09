import Foundation

// MARK: - Requests

public struct BankIdSeAuthRequest: Encodable {
    public let ssn: String?
    public let ipAddress: String?
    public let callbackUrl: String?
    public let pinRequired: Bool?
    public let intent: String?
    public let orgNumber: String?
    public let requestAddress: Bool?
    public let refId: String?

    public init(
        ssn: String? = nil,
        ipAddress: String? = nil,
        callbackUrl: String? = nil,
        pinRequired: Bool? = nil,
        intent: String? = nil,
        orgNumber: String? = nil,
        requestAddress: Bool? = nil,
        refId: String? = nil
    ) {
        self.ssn = ssn
        self.ipAddress = ipAddress
        self.callbackUrl = callbackUrl
        self.pinRequired = pinRequired
        self.intent = intent
        self.orgNumber = orgNumber
        self.requestAddress = requestAddress
        self.refId = refId
    }
}

public struct BankIdSePhoneAuthRequest: Encodable {
    public let ssn: String
    public let callInitiator: String
    public let callbackUrl: String?
    public let pinRequired: Bool?
    public let intent: String?
    public let orgNumber: String?
    public let requestAddress: Bool?
    public let refId: String?

    public init(
        ssn: String,
        callInitiator: String,
        callbackUrl: String? = nil,
        pinRequired: Bool? = nil,
        intent: String? = nil,
        orgNumber: String? = nil,
        requestAddress: Bool? = nil,
        refId: String? = nil
    ) {
        self.ssn = ssn
        self.callInitiator = callInitiator
        self.callbackUrl = callbackUrl
        self.pinRequired = pinRequired
        self.intent = intent
        self.orgNumber = orgNumber
        self.requestAddress = requestAddress
        self.refId = refId
    }
}

public struct BankIdSeSignRequest: Encodable {
    public let text: String
    public let ssn: String?
    public let ipAddress: String?
    public let callbackUrl: String?
    public let pinRequired: Bool?
    public let digest: String?
    public let orgNumber: String?
    public let requestAddress: Bool?
    public let refId: String?

    public init(
        text: String,
        ssn: String? = nil,
        ipAddress: String? = nil,
        callbackUrl: String? = nil,
        pinRequired: Bool? = nil,
        digest: String? = nil,
        orgNumber: String? = nil,
        requestAddress: Bool? = nil,
        refId: String? = nil
    ) {
        self.text = text
        self.ssn = ssn
        self.ipAddress = ipAddress
        self.callbackUrl = callbackUrl
        self.pinRequired = pinRequired
        self.digest = digest
        self.orgNumber = orgNumber
        self.requestAddress = requestAddress
        self.refId = refId
    }
}

public struct BankIdSePhoneSignRequest: Encodable {
    public let ssn: String
    public let callInitiator: String
    public let text: String
    public let callbackUrl: String?
    public let pinRequired: Bool?
    public let digest: String?
    public let orgNumber: String?
    public let requestAddress: Bool?
    public let refId: String?

    public init(
        ssn: String,
        callInitiator: String,
        text: String,
        callbackUrl: String? = nil,
        pinRequired: Bool? = nil,
        digest: String? = nil,
        orgNumber: String? = nil,
        requestAddress: Bool? = nil,
        refId: String? = nil
    ) {
        self.ssn = ssn
        self.callInitiator = callInitiator
        self.text = text
        self.callbackUrl = callbackUrl
        self.pinRequired = pinRequired
        self.digest = digest
        self.orgNumber = orgNumber
        self.requestAddress = requestAddress
        self.refId = refId
    }
}

public struct BankIdSeVerifyRequest: Encodable {
    public let qrCode: String
    public init(qrCode: String) { self.qrCode = qrCode }
}

public struct BankIdSeVerifyResponse: Decodable {
    public let ssn: String
    public let name: String
    public let givenName: String
    public let surname: String
    public let age: Int?
    public let verifiedAt: String?
}

// MARK: - Status enums + variants

public enum BankIdSeStatus: Decodable {
    case pending(BankIdSePending)
    case completed(BankIdSeCompleted)
    case failed(BankIdSeFailed)

    private enum DiscriminatorKey: String, CodingKey { case status }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DiscriminatorKey.self)
        let status = try container.decode(String.self, forKey: .status)
        switch status {
        case "PENDING":   self = .pending(try BankIdSePending(from: decoder))
        case "COMPLETED": self = .completed(try BankIdSeCompleted(from: decoder))
        case "FAILED":    self = .failed(try BankIdSeFailed(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .status, in: container, debugDescription: "Unknown bankid-se status: \(status)")
        }
    }
}

public enum BankIdSePhoneStatus: Decodable {
    case pending(BankIdSePendingPhone)
    case completed(BankIdSeCompleted)
    case failed(BankIdSeFailed)

    private enum DiscriminatorKey: String, CodingKey { case status }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DiscriminatorKey.self)
        let status = try container.decode(String.self, forKey: .status)
        switch status {
        case "PENDING":   self = .pending(try BankIdSePendingPhone(from: decoder))
        case "COMPLETED": self = .completed(try BankIdSeCompleted(from: decoder))
        case "FAILED":    self = .failed(try BankIdSeFailed(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .status, in: container, debugDescription: "Unknown bankid-se phone status: \(status)")
        }
    }
}

public struct BankIdSePending: Decodable {
    public let id: String
    public let refId: String?
    public let autoStartToken: String?
    public let qrStartToken: String?
    public let qrStartSecret: String?
    public let hintCode: String?
}

public struct BankIdSePendingPhone: Decodable {
    public let id: String
    public let refId: String?
    public let hintCode: String?
}

public struct BankIdSeCompleted: Decodable {
    public let id: String
    public let refId: String?
    public let ssn: String
    public let name: String
    public let givenName: String
    public let surname: String
    public let certStartDate: String?
    public let address: String?
    public let companySignatoryText: String?
}

public struct BankIdSeFailed: Decodable {
    public let id: String
    public let refId: String?
    public let error: String
}

// MARK: - Endpoint

public final class BankIdSeEndpoint {
    private let transport: Transport
    internal init(_ transport: Transport) { self.transport = transport }

    public func auth(_ req: BankIdSeAuthRequest) async throws -> BankIdSeStatus {
        try await transport.post("/v3/bankid-se/auth", body: req)
    }

    public func phoneAuth(_ req: BankIdSePhoneAuthRequest) async throws -> BankIdSePhoneStatus {
        try await transport.post("/v3/bankid-se/phone/auth", body: req)
    }

    public func sign(_ req: BankIdSeSignRequest) async throws -> BankIdSeStatus {
        try await transport.post("/v3/bankid-se/sign", body: req)
    }

    public func phoneSign(_ req: BankIdSePhoneSignRequest) async throws -> BankIdSePhoneStatus {
        try await transport.post("/v3/bankid-se/phone/sign", body: req)
    }

    public func verify(_ req: BankIdSeVerifyRequest) async throws -> BankIdSeVerifyResponse {
        try await transport.post("/v3/bankid-se/verify", body: req)
    }

    public func ageVerification(_ req: AgeVerificationRequest) async throws -> AgeVerificationStatus {
        try await transport.post("/v3/bankid-se/age-verification", body: req)
    }

    public func authStatus(id: String) async throws -> BankIdSeStatus {
        try await transport.get("/v3/bankid-se/auth/\(id)")
    }

    public func signStatus(id: String) async throws -> BankIdSeStatus {
        try await transport.get("/v3/bankid-se/sign/\(id)")
    }

    public func ageVerificationStatus(id: String) async throws -> AgeVerificationStatus {
        try await transport.get("/v3/bankid-se/age-verification/\(id)")
    }

    public func cancelAuth(id: String) async throws {
        try await transport.delete("/v3/bankid-se/auth/\(id)")
    }

    public func cancelSign(id: String) async throws {
        try await transport.delete("/v3/bankid-se/sign/\(id)")
    }

    public func cancelAgeVerification(id: String) async throws {
        try await transport.delete("/v3/bankid-se/age-verification/\(id)")
    }

    public func waitForAuth(id: String, opts: PollOptions = .init()) async throws -> BankIdSeStatus {
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

    public func waitForSign(id: String, opts: PollOptions = .init()) async throws -> BankIdSeStatus {
        let deadline = Date().addingTimeInterval(opts.timeout)
        while true {
            let status = try await signStatus(id: id)
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
