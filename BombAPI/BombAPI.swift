import Foundation
import PromiseKit
import PMKFoundation

public enum BombAPIError: Error {
    case noLiveVideos
}

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

    public func getShows() -> Promise<[Show]> {
        let queryItems = [
            URLQueryItem(name: "field_list", value: Show.fields)
        ]
        let request = buildRequest(for: "video_shows", queryItems: queryItems)
        return firstly {
            session.dataTask(.promise, with: request).validate()
        }.map { response -> [Show] in
            try self.decoder.decode(WrappedResponse.self, from: response.data).results
        }
    }

    public func recentVideos() -> Promise<[BombVideo]> {
        let queryItems = [
            URLQueryItem(name: "field_list", value: BombVideo.fields)
        ]
        let request = buildRequest(for: "videos", queryItems: queryItems)
        return firstly {
            session.dataTask(.promise, with: request).validate()
        }.map { response -> [BombVideo] in
            try self.decoder.decode(WrappedResponse.self, from: response.data).results
        }.filterValues{
            $0.isAvailable
        }
    }

    public func liveVideo() -> Promise<LiveVideo> {
        let request = buildRequest(for: "video/current-live")
        return firstly {
            session.dataTask(.promise, with: request).validate()
        }.map { response -> LiveVideo in
            let response = try self.decoder.decode(LiveVideoResponse.self, from: response.data)
            guard let video = response.video else {
                throw BombAPIError.noLiveVideos
            }
            return video
        }
    }

    public func getAuthenticationToken(appName: String, code: String) -> Promise<AuthenticationResponse> {
        let request = "https://giantbomb.com/app/\(appName)/get-result?regCode=\(code)&format=json"
        let url = URL(string: request)!
        return firstly {
            session.dataTask(.promise, with: url).validate()
        }.map { response -> AuthenticationResponse in
            try self.decoder.decode(AuthenticationResponse.self, from: response.data)
        }
    }

    @discardableResult
    public func saveTime(video: BombVideo, position: Int) -> Promise<Void> {
        let queryItems = [
            URLQueryItem(name: "video_id", value: String(video.id)),
            URLQueryItem(name: "time_to_save", value: String(position))
        ]
        let request = buildRequest(for: "video/save-time", queryItems: queryItems)

        return session.dataTask(.promise, with: request).validate().asVoid()
    }

    private func buildRequest(for resource: String, queryItems: [URLQueryItem] = []) -> URLRequest {
        var components = URLComponents(url: URL(string: resource)!, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: CredentialProvider.credential),
            URLQueryItem(name: "format", value: "json")
        ]
        components.queryItems?.append(contentsOf: queryItems)
        return URLRequest(url: components.url(relativeTo: baseUrl)!)
    }
}
