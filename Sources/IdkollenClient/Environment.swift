import Foundation

public enum Environment {
    case production
    case staging

    public var baseUrl: String {
        switch self {
        case .production: return "https://api.idkollen.se"
        case .staging:    return "https://stgapi.idkollen.se"
        }
    }
}
