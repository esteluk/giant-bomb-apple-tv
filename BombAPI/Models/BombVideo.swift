import Foundation

public struct BombVideo {
    let name: String
    let id: Int
    let duration: TimeInterval
    public let images: BombVideoImages
    public let resumePoint: TimeInterval?
    public let publishedOn: Date
    let videoDescription: String
    let videoUrls: BombVideoUrls
}

extension BombVideo: Decodable, Hashable {
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case id = "id"
        case duration = "length_seconds"
        case images = "image"
        case resumePoint = "saved_time"
        case publishedOn = "publish_date"
        case videoDescription = "deck"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        id = try container.decode(Int.self, forKey: .id)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        images = try container.decode(BombVideoImages.self, forKey: .images)
        if let savedTime = try container.decodeIfPresent(String.self, forKey: .resumePoint) {
            resumePoint = floor(Double(savedTime) ?? 0)
        } else {
            resumePoint = nil
        }

        publishedOn = try container.decode(Date.self, forKey: .publishedOn)
        videoDescription = try container.decode(String.self, forKey: .videoDescription)
        videoUrls = try BombVideoUrls(from: decoder)
    }
}
