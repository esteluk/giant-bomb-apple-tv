import Foundation

public struct Images: Decodable, Hashable {
    enum CodingKeys: String, CodingKey {
        case small = "small_url"
        case medium = "screen_url"
        case original = "original_url"
    }

    public let small: URL
    public let medium: URL
    public let original: URL
}

// Should be only temporary
public extension URL {
    var fixed: URL {
        let string = self.absoluteString
        if string.hasSuffix(".png"),
            let range = string.range(of: ".png", options: .backwards) {
            return URL(string: string.replacingOccurrences(of: ".png", with: ".jpg", range: range))!
        }
        return URL(string: string)!
    }
}
