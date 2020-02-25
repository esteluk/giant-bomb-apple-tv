import Foundation
import PromiseKit
import PMKFoundation

public class BombAPI {
    public static func setAPIKey(_ key: String) {
        CredentialProvider.credential = key
    }

    private let baseUrl = URL(string: "https://www.giantbomb.com/api/")!

    public init() {}

    public func recentVideos() -> Promise<[BombVideo]> {
        let session = URLSession.shared

        let request = buildRequest(for: "videos")
        return firstly {
            session.dataTask(.promise, with: request).validate()
        }.map { response -> [BombVideo] in
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.defaultBombFormatter)
            return try decoder.decode(VideosResponse.self, from: response.data).results
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


