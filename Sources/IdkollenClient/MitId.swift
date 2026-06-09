import Foundation

// MARK: - Requests

public struct MitIdAuthRequest: Encodable {
    public let redirectUrl: String?
    public let referenceText: String?
    public let requestPhone: Bool?
    public let requestEmail: Bool?
    public let requestAddress: Bool?
    public let refId: String?

    public init(
        redirectUrl: String? = nil,
        referenceText: String? = nil,
        requestPhone: Bool? = nil,
        requestEmail: Bool? = nil,
        requestAddress: Bool? = nil,
        refId: String? = nil
    ) {
        self.redirectUrl = redirectUrl
        self.referenceText = referenceText
        self.requestPhone = requestPhone
        self.requestEmail = requestEmail
        self.requestAddress = requestAddress
        self.refId = refId
    }
}

public struct MitIdBackchannelAuthRequest: Encodable {
    public let ssn: String
    public let bindingMessage: String
    public let callbackUrl: String?
    public let refId: String?

    public init(
        ssn: String,
        bindingMessage: String,
        callbackUrl: String? = nil,
        refId: String? = nil
    ) {
        self.ssn = ssn
        self.bindingMessage = bindingMessage
        self.callbackUrl = callbackUrl
        self.refId = refId
    }
}

public struct MitIdSignRequest: Encodable {
    public let text: String
    public let redirectUrl: String?
    public let refId: String?

    public init(
        text: String,
        redirectUrl: String? = nil,
        refId: String? = nil
    ) {
        self.text = text
        self.redirectUrl = redirectUrl
        self.refId = refId
    }
}

// MARK: - Helper structs

public struct MitIdSignResult: Decodable {
    public let checksum: String
}

// MARK: - Status enum + variants

public enum MitIdStatus: Decodable {
    case pending(MitIdPending)
    case completed(MitIdCompleted)
    case failed(MitIdFailed)

    private enum DiscriminatorKey: String, CodingKey { case status }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DiscriminatorKey.self)
        let status = try container.decode(String.self, forKey: .status)
        switch status {
        case "PENDING":   self = .pending(try MitIdPending(from: decoder))
        case "COMPLETED": self = .completed(try MitIdCompleted(from: decoder))
        case "FAILED":    self = .failed(try MitIdFailed(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .status, in: container, debugDescription: "Unknown mitid status: \(status)")
        }
    }
}

public struct MitIdPending: Decodable {
    public let id: String
    public let refId: String?
    public let url: String?
    public let bindingMessage: String?
}

public struct MitIdCompleted: Decodable {
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
    public let signResult: MitIdSignResult?
}

public struct MitIdFailed: Decodable {
    public let id: String
    public let refId: String?
    public let error: String
}

// MARK: - Endpoint

public final class MitIdEndpoint {
    private let transport: Transport
    internal init(_ transport: Transport) { self.transport = transport }

    public func auth(_ req: MitIdAuthRequest) async throws -> MitIdStatus {
        try await transport.post("/v3/mitid/auth", body: req)
    }

    public func backchannelAuth(_ req: MitIdBackchannelAuthRequest) async throws -> MitIdStatus {
        try await transport.post("/v3/mitid/backchannel/auth", body: req)
    }

    public func sign(_ req: MitIdSignRequest) async throws -> MitIdStatus {
        try await transport.post("/v3/mitid/sign", body: req)
    }

    public func authStatus(id: String) async throws -> MitIdStatus {
        try await transport.get("/v3/mitid/auth/\(id)")
    }

    public func signStatus(id: String) async throws -> MitIdStatus {
        try await transport.get("/v3/mitid/sign/\(id)")
    }

    public func cancelAuth(id: String) async throws {
        try await transport.delete("/v3/mitid/auth/\(id)")
    }

    public func cancelSign(id: String) async throws {
        try await transport.delete("/v3/mitid/sign/\(id)")
    }

    public func waitForAuth(id: String, opts: PollOptions = .init()) async throws -> MitIdStatus {
        try await poll({ try await self.authStatus(id: id) }, opts: opts)
    }

    public func waitForSign(id: String, opts: PollOptions = .init()) async throws -> MitIdStatus {
        try await poll({ try await self.signStatus(id: id) }, opts: opts)
    }

    private func poll(_ fn: @escaping () async throws -> MitIdStatus, opts: PollOptions) async throws -> MitIdStatus {
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
