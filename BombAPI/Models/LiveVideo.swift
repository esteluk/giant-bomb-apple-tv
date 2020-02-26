import Foundation

public struct LiveVideo: Decodable, Hashable {
    let title: String
    let image: String // Possibly a Images object
    let stream: URL
}

struct LiveVideoResponse: Decodable {
    let video: LiveVideo?
}
