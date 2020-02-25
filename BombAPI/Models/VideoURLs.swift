import Foundation

struct BombVideoUrls: Decodable, Hashable {
    enum CodingKeys: String, CodingKey {
        case low = "low_url"
        case medium = "high_url"
        case high = "hd_url"
    }

    let low: URL
    let medium: URL
    let high: URL
}
