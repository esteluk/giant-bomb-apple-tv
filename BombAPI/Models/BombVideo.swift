import AVFoundation
import Foundation

public struct BombVideo {
    public let name: String
    public let id: Int
    public let duration: TimeInterval
    public let images: Images
    public let resumePoint: TimeInterval?
    public let premium: Bool
    public let publishedOn: Date
    public let videoDescription: String
    public let videoUrls: VideoUrls
}

extension BombVideo: Decodable, Hashable {
    enum CodingKeys: String, CodingKey, CaseIterable {
        case name
        case id
        case duration = "length_seconds"
        case images = "image"
        case premium
        case publishedOn = "publish_date"
        case resumePoint = "saved_time"
        case videoDescription = "deck"
        case lowUrl = "low_url"
        case medUrl = "med_url"
        case highUrl = "high_url"
    }

    static var fields = CodingKeys.allCases.map { $0.rawValue }.joined(separator: ",")

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        id = try container.decode(Int.self, forKey: .id)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        images = try container.decode(Images.self, forKey: .images)
        if let savedTime = try container.decodeIfPresent(String.self, forKey: .resumePoint) {
            resumePoint = floor(Double(savedTime) ?? 0)
        } else {
            resumePoint = nil
        }

        premium = try container.decode(Bool.self, forKey: .premium)
        publishedOn = try container.decode(Date.self, forKey: .publishedOn)
        videoDescription = try container.decode(String.self, forKey: .videoDescription)
        videoUrls = try VideoUrls(from: decoder)
    }

    var isAvailable: Bool {
        return videoUrls.isUrlAvailable
    }

    public var launchUrl: URL {
        return URL(string: "giantbomb-tv://video/\(id)")!
    }
}

public extension BombVideo {
    var externalMetadata: [AVMetadataItem] {
        let title = AVMutableMetadataItem(identifier: .commonIdentifierTitle, value: name)
        let description = AVMutableMetadataItem(identifier: .commonIdentifierDescription, value: videoDescription)

        return [title, description]
    }
}

extension AVMutableMetadataItem {
    convenience init(identifier: AVMetadataIdentifier, value: String) {
        self.init()
        self.keySpace = .common
        self.identifier = identifier
        self.locale = .current
        self.value = value as (NSCopying & NSObjectProtocol)?
    }
}

