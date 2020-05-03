import Foundation

public struct Show: Decodable, Hashable {
    enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case images = "image"
        case isActive = "active"
        case isVisibleInNav = "display_nav"
        case latestVideos = "latest"
        case position
        case showDescription = "deck"
        case title
    }

    static var fields = CodingKeys.allCases.map { $0.rawValue }.joined(separator: ",")

    let id: Int
    public let images: Images
    public let isActive: Bool
    public let isVisibleInNav: Bool
    private let latestVideos: [BombVideo]?
    public let position: Int
    public let showDescription: String?
    public let title: String

    public var latestVideo: BombVideo? {
        return latestVideos?.first
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        images = try container.decode(Images.self, forKey: .images)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? false
        isVisibleInNav = try container.decodeIfPresent(Bool.self, forKey: .isVisibleInNav) ?? false
        latestVideos = try container.decodeIfPresent([BombVideo].self, forKey: .latestVideos)
        position = try container.decode(Int.self, forKey: .position)
        showDescription = try container.decodeIfPresent(String.self, forKey: .showDescription)
        title = try container.decode(String.self, forKey: .title)
    }
}

extension Show: Comparable {
    public static func < (lhs: Show, rhs: Show) -> Bool {
        return lhs.title < rhs.title
    }
}

extension Show: Equatable {
    public static func == (lhs: Show, rhs: Show) -> Bool {
        return lhs.id == rhs.id
    }
}
