import Foundation

struct SavedVideoProgress: Decodable {
    enum CodingKeys: String, CodingKey {
        case savedAtDate = "savedOn"
        case savedTime
        case videoId
    }

    public let savedAtDate: Date
    public let savedTime: TimeInterval
    public let videoId: Int

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let savedAtDateString = try container.decode(String.self, forKey: .savedAtDate)
        guard let date = DateFormatter.savedDateFormatter.date(from: savedAtDateString) else {
            throw DecodingError.dataCorruptedError(forKey: .savedAtDate,
                                                   in: container,
                                                   debugDescription: "Unexpected date format")
        }
        savedAtDate = date

        let savedTimeString = try container.decode(String.self, forKey: .savedTime)
        savedTime = TimeInterval(savedTimeString) ?? 0
        videoId = try container.decode(Int.self, forKey: .videoId)
    }
}

extension SavedVideoProgress: Comparable {
    static func < (lhs: SavedVideoProgress, rhs: SavedVideoProgress) -> Bool {
        return lhs.savedAtDate > rhs.savedAtDate
    }
}

struct SavedTimesResponse: Decodable {
    let savedTimes: [SavedVideoProgress]
}
