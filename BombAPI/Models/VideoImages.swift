import Foundation

public struct VideoImages: Decodable, Hashable {
    enum CodingKeys: String, CodingKey {
        case small = "small_url"
        case medium = "screen_url"
        case original = "original_url"
    }
    public let small: URL
    public let medium: URL
    public let original: URL
}
