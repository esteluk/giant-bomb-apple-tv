import Foundation

public struct Show: Decodable, Hashable {
    enum CodingKeys: String, CodingKey {
        case id
        case images = "image"
        case isActive = "active"
        case latestVideos = "latest"
        case showDescription = "deck"
        case title
    }

    let id: Int
    public let images: Images
    let isActive: Bool
    private let latestVideos: [BombVideo]?
    public let showDescription: String
    public let title: String

    var latestVideo: BombVideo? {
        return latestVideos?.first
    }
}
