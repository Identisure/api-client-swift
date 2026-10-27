import Foundation

public enum Environment {
    case production
    case staging

    public var baseUrl: String {
        switch self {
        case .production: return "https://api.identisure.com"
        case .staging:    return "https://stgapi.identisure.com"
        }
    }
}
