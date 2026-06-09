import Foundation

public struct AgeVerificationRequest: Encodable {
    public let minAge: Int?
    public let maxAge: Int?
    public let refId: String?
    public let callbackUrl: String?
    public let redirectUrl: String?

    public init(minAge: Int? = nil, maxAge: Int? = nil, refId: String? = nil, callbackUrl: String? = nil, redirectUrl: String? = nil) {
        self.minAge = minAge
        self.maxAge = maxAge
        self.refId = refId
        self.callbackUrl = callbackUrl
        self.redirectUrl = redirectUrl
    }
}

public enum AgeVerificationStatus: Decodable {
    case pending(AgeVerificationPending)
    case completed(AgeVerificationCompleted)
    case failed(AgeVerificationFailed)

    private enum DiscriminatorKey: String, CodingKey { case status }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DiscriminatorKey.self)
        let status = try container.decode(String.self, forKey: .status)
        switch status {
        case "PENDING":   self = .pending(try AgeVerificationPending(from: decoder))
        case "COMPLETED": self = .completed(try AgeVerificationCompleted(from: decoder))
        case "FAILED":    self = .failed(try AgeVerificationFailed(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .status, in: container, debugDescription: "Unknown age verification status: \(status)")
        }
    }
}

public struct AgeVerificationPending: Decodable {
    public let id: String
    public let url: String?
    public let minAge: Int?
    public let maxAge: Int?
}

public struct AgeVerificationCompleted: Decodable {
    public let id: String
    public let ageVerified: Bool
}

public struct AgeVerificationFailed: Decodable {
    public let id: String
    public let error: String
}
