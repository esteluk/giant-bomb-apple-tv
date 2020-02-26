import AVFoundation
import Foundation

public struct VideoUrls: Decodable, Hashable {
    enum CodingKeys: String, CodingKey {
        case low = "low_url"
        case medium = "high_url"
        case high = "hd_url"
    }

    private let low: URL?
    private let medium: URL?
    private let high: URL?

    var isUrlAvailable: Bool {
        return high != nil
            || medium != nil
            || low != nil
    }

    public var lowQuality: URL? {
        return low?.withCredential
    }

    public var mediumQuality: URL? {
        return medium?.withCredential ?? low?.withCredential
    }

    public var highQuality: URL? {
        return high?.withCredential ?? medium?.withCredential ?? low?.withCredential
    }
}

private extension URL {
    var withCredential: URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "api_key", value: CredentialProvider.credential)]
        return components.url!
    }
}
