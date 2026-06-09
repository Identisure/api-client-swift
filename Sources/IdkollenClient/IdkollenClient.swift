import Foundation

public final class IdkollenClient {
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

public final class IdkollenClientBuilder {
    private let clientId: String
    private let clientSecret: String
    private var env: Environment = .production
    private var customBaseUrl: String?
    private var customSession: URLSession?

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

    public func build() -> IdkollenClient {
        let session = customSession ?? URLSession.shared
        let baseUrl = customBaseUrl ?? env.baseUrl
        let transport = Transport(session: session, baseUrl: baseUrl, clientId: clientId, clientSecret: clientSecret)
        return IdkollenClient(transport: transport)
    }
}
