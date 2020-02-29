import Foundation

public struct Show: Decodable, Hashable {
    enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case images = "image"
        case isActive = "active"
        case latestVideos = "latest"
        case showDescription = "deck"
        case title
    }

    static var fields = CodingKeys.allCases.map { $0.rawValue }.joined(separator: ",")

    let id: Int
    public let images: Images
    public let isActive: Bool
    private let latestVideos: [BombVideo]?
    public let showDescription: String
    public let title: String

    public var latestVideo: BombVideo? {
        return latestVideos?.first
    }
}

extension Show: Comparable {
    public static func < (lhs: Show, rhs: Show) -> Bool {
        return lhs.title < rhs.title
    }
}
