import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class IdentisureClient {
    public let bankIdSe: BankIdSeEndpoint
    public let bankIdNo: BankIdNoEndpoint
    public let freja: FrejaEndpoint
    public let mitId: MitIdEndpoint
    public let ftn: FtnEndpoint
    public let vipps: VippsEndpoint
    public let document: DocumentEndpoint

    internal init(transport: Transport) {
        self.bankIdSe = BankIdSeEndpoint(transport)
        self.bankIdNo = BankIdNoEndpoint(transport)
        self.freja = FrejaEndpoint(transport)
        self.mitId = MitIdEndpoint(transport)
        self.ftn = FtnEndpoint(transport)
        self.vipps = VippsEndpoint(transport)
        self.document = DocumentEndpoint(transport)
    }
}

public final class IdentisureClientBuilder {
    private let clientId: String
    private let clientSecret: String
    private var env: Environment = .production
    private var customBaseUrl: String?
    private var customSession: URLSession?
    private var requestTimeout: TimeInterval = 30

    public init(clientId: String, clientSecret: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
    }

    @discardableResult
    public func environment(_ env: Environment) -> Self {
        self.env = env
        return self
    }

    @discardableResult
    public func baseUrl(_ url: String) -> Self {
        self.customBaseUrl = url
        return self
    }

    @discardableResult
    public func urlSession(_ session: URLSession) -> Self {
        self.customSession = session
        return self
    }

    /// Timeout in seconds for each HTTP request. Defaults to 30. Must be positive.
    @discardableResult
    public func timeout(_ seconds: TimeInterval) -> Self {
        precondition(seconds > 0, "Timeout must be positive")
        self.requestTimeout = seconds
        return self
    }

    public func build() -> IdentisureClient {
        let session = customSession ?? URLSession.shared
        let baseUrl = customBaseUrl ?? env.baseUrl
        let transport = Transport(session: session, baseUrl: baseUrl, clientId: clientId, clientSecret: clientSecret, timeout: requestTimeout)
        return IdentisureClient(transport: transport)
    }
}
