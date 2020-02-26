import Foundation
import PromiseKit
import PMKFoundation

public class BombAPI {
    public static func setAPIKey(_ key: String) {
        CredentialProvider.credential = key
    }

    private let baseUrl = URL(string: "https://www.giantbomb.com/api/")!
    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.defaultBombFormatter)
        return decoder
    }()
    private let session: URLSession

    public init(session: URLSession = URLSession.shared) {
        self.session = session
    }

    public func recentVideos() -> Promise<[BombVideo]> {
        let request = buildRequest(for: "videos")
        return firstly {
            session.dataTask(.promise, with: request).validate()
        }.map { response -> [BombVideo] in
            try self.decoder.decode(WrappedResponse.self, from: response.data).results
        }.filterValues{
            $0.isAvailable
        }
    }

    public func getShows() -> Promise<[Show]> {
        let request = buildRequest(for: "video_shows")
        return firstly {
            session.dataTask(.promise, with: request).validate()
        }.map { response -> [Show] in
            try self.decoder.decode(WrappedResponse.self, from: response.data).results
        }
    }

    private func buildRequest(for resource: String) -> URLRequest {
        var components = URLComponents(url: URL(string: resource)!, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: CredentialProvider.credential),
            URLQueryItem(name: "format", value: "json")
        ]
        return URLRequest(url: components.url(relativeTo: baseUrl)!)
    }
}

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


