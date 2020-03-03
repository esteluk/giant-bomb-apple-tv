import Foundation

public struct LiveVideo: Decodable, Hashable {
    public let title: String
    public let image: String // Possibly a Images object
    public let stream: URL
}

struct LiveVideoResponse: Decodable {
    let video: LiveVideo?
}
