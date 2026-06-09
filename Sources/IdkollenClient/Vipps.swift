import Foundation

// MARK: - Requests

public struct VippsAuthRequest: Encodable {
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

public struct VippsBackchannelAuthRequest: Encodable {
    public let phone: String
    public let requestSsn: Bool?
    public let requestEmail: Bool?
    public let requestAddress: Bool?
    public let callbackUrl: String?
    public let refId: String?

    public init(
        phone: String,
        requestSsn: Bool? = nil,
        requestEmail: Bool? = nil,
        requestAddress: Bool? = nil,
        callbackUrl: String? = nil,
        refId: String? = nil
    ) {
        self.phone = phone
        self.requestSsn = requestSsn
        self.requestEmail = requestEmail
        self.requestAddress = requestAddress
        self.callbackUrl = callbackUrl
        self.refId = refId
    }
}

// MARK: - Status enum + variants

public enum VippsStatus: Decodable {
    case pending(VippsPending)
    case completed(VippsCompleted)
    case failed(VippsFailed)

    private enum DiscriminatorKey: String, CodingKey { case status }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DiscriminatorKey.self)
        let status = try container.decode(String.self, forKey: .status)
        switch status {
        case "PENDING":   self = .pending(try VippsPending(from: decoder))
        case "COMPLETED": self = .completed(try VippsCompleted(from: decoder))
        case "FAILED":    self = .failed(try VippsFailed(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .status, in: container, debugDescription: "Unknown vipps status: \(status)")
        }
    }
}

public struct VippsPending: Decodable {
    public let id: String
    public let refId: String?
    public let url: String?
}

public struct VippsCompleted: Decodable {
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

public struct VippsFailed: Decodable {
    public let id: String
    public let refId: String?
    public let error: String
}

// MARK: - Endpoint

public final class VippsEndpoint {
    private let transport: Transport
    internal init(_ transport: Transport) { self.transport = transport }

    public func auth(_ req: VippsAuthRequest) async throws -> VippsStatus {
        try await transport.post("/v3/vipps/auth", body: req)
    }

    public func backchannelAuth(_ req: VippsBackchannelAuthRequest) async throws -> VippsStatus {
        try await transport.post("/v3/vipps/backchannel/auth", body: req)
    }

    public func authStatus(id: String) async throws -> VippsStatus {
        try await transport.get("/v3/vipps/auth/\(id)")
    }

    public func cancelAuth(id: String) async throws {
        try await transport.delete("/v3/vipps/auth/\(id)")
    }

    public func waitForAuth(id: String, opts: PollOptions = .init()) async throws -> VippsStatus {
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
}
