import AVFoundation
import Foundation

public struct LiveVideo: Decodable, Hashable {

    enum CodingKeys: String, CodingKey {
        case title
        case image
        case stream
    }

    public let title: String
    public let image: URL // Possibly a Images object
    public let stream: URL

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)

        let imageString = try container.decode(String.self, forKey: .image)
        if let image = URL(string: "https://\(imageString)") {
            self.image = image
        } else {
            throw DecodingError.dataCorruptedError(forKey: .image,
                                                   in: container,
                                                   debugDescription: "Invalid image url")
        }
        stream = try container.decode(URL.self, forKey: .stream)
    }
}

public extension LiveVideo {
    var externalMetadata: [AVMetadataItem] {
        let title = AVMutableMetadataItem(identifier: .commonIdentifierTitle, value: self.title)

        return [title]
    }
}


struct LiveVideoResponse: Decodable {
    let video: LiveVideo?
}
