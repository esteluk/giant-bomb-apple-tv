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
    let isActive: Bool?
    let isVisibleInNav: Bool?
    private let latestVideos: [BombVideo]?
    public let position: Int
    public let showDescription: String?
    public let title: String

    public var latestVideo: BombVideo? {
        return latestVideos?.first
    }

    /// Hardcodes the only "non-sequential" shows to be:
    /// * Quick Looks, Podcasts, PlayDate, E3 vs GB, Reviews, Game Tapes, Demo Derby, Breakfast + Ben, Lockdown 2020,
    public var isSequentialContent: Bool {
        return [3, 5, 10, 12, 18, 20, 21, 28, 40, 45, 47, 49, 74, 86].contains(id)
    }

    public var isPromoted: Bool {
        return (isActive ?? false) && (isVisibleInNav ?? false)
    }

}

extension Show: Comparable {
    public static func < (lhs: Show, rhs: Show) -> Bool {
        return lhs.title < rhs.title
    }
}
