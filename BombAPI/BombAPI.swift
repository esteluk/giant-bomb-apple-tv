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
    private let cache: LocalCache
    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.defaultBombFormatter)
        return decoder
    }()
    private let session: URLSession

    init(session: URLSession, cache: LocalCache = LocalCache.shared) {
        self.cache = cache
        self.session = session
    }

    public init(session: URLSession = URLSession.shared) {
        self.cache = LocalCache.shared
        self.session = session
    }

    /// Gets an array of all the Show objects that are available within the API. Examples of "Show" objects
    /// are "Quick Looks", "Unprofessional Fridays" or "Mass Alex"
    /// - Returns: A promise for an array of Shows
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

    /// Gets a paged list of the 100 most recent videos that are fall within the provided filter. If no filter is provided,
    /// this returns the 100 most recent videos published to the site to which the authorising user has access.
    /// - Parameters:
    ///   - filter: VideoFilter object describing which videos should be returned from this request. Defaults to nil.
    ///   - offset: If provided, the request skips the first <offset> number of results.
    /// - Returns: An array of BombVideo objects that meet the filter and offset requirements.
    public func videos(filter: VideoFilter? = nil, offset: Int = 0) -> Promise<[BombVideo]> {
        var queryItems = [
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "field_list", value: BombVideo.fields)
        ]

        if let filter = filter {
            queryItems.append(filter.queryItem)
        }

        let request = buildRequest(for: "videos", queryItems: queryItems)
        return firstly {
            session.dataTask(.promise, with: request).validate()
        }.map { response -> [BombVideo] in
            try self.decoder.decode(WrappedResponse.self, from: response.data).results
        }.get { videos in
            videos.forEach { self.cache.storeVideo($0) }
        }.filterValues{
            $0.isAvailable
        }
    }

    public func search(query: String, page: Int = 1) -> Promise<WrappedResponse<[BombVideo]>> {
        let queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "resources", value: "video")
        ]

        let request = buildRequest(for: "search", queryItems: queryItems)
        return firstly {
            session.dataTask(.promise, with: request).validate()
        }.map { response in
            try self.decoder.decode(WrappedResponse.self, from: response.data)
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
        cache.updateResumePoint(TimeInterval(position), for: video)
        let request = buildRequest(for: "video/save-time", queryItems: queryItems)
        return session.dataTask(.promise, with: request).validate().asVoid()
    }

    @discardableResult
    public func markWatched(video: BombVideo) -> Promise<Void> {
        let queryItems = [
            URLQueryItem(name: "video_id", value: String(video.id))
        ]
        let request = buildRequest(for: "video/mark-watched", queryItems: queryItems)
        return session.dataTask(.promise, with: request).validate().asVoid()
    }

    public func getRecentlyWatched(limit: Int = 2) -> Promise<[BombVideo]> {
        let request = buildRequest(for: "video/get-all-saved-times")

        return firstly {
            session.dataTask(.promise, with: request).validate()
        }.map { response -> SavedTimesResponse in
            try self.decoder.decode(SavedTimesResponse.self, from: response.data)
        }.map {
            $0.savedTimes
        }.get { savedTimes in
            savedTimes.forEach { self.cache.updateResumePoint(point: $0) }
        }.sortedValues()
        .map {
            $0.prefix(1)
        }.thenMap { savedTime -> Promise<BombVideo> in
            self.video(for: savedTime.videoId)
//        }.filterValues {
//            $0.isResumable
        }.map {
            Array($0.prefix(limit))
        }
    }

    private func video(for id: Int) -> Promise<BombVideo> {
        if let video = cache.requestVideo(for: id) {
            return Promise.value(video)
        }

        return requestVideo(for: id)
    }

    private func requestVideo(for id: Int) -> Promise<BombVideo> {
        let request = buildRequest(for: "video/\(String(id))")
        return firstly {
            session.dataTask(.promise, with: request).validate()
        }.map { response in
            try self.decoder.decode(WrappedResponse.self, from: response.data).results
        }.get { video in
            self.cache.storeVideo(video)
        }
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

extension BombAPI: ResumeTimeProvider {
    public func resumePoint(for video: BombVideo) -> TimeInterval? {
        return cache.resumePoint(for: video)
    }
    public func isCompleted(video: BombVideo) -> Bool {
        guard let resumePoint = cache.resumePoint(for: video) else { return false }
        return resumePoint > video.duration - 10
    }

    public func isResumable(video: BombVideo) -> Bool {
        guard let resumePoint = cache.resumePoint(for: video) else { return false }
        return resumePoint > 0 && resumePoint < video.duration - 10
    }

    public func progress(for video: BombVideo) -> Float? {
        guard isResumable(video: video), let resumePoint = cache.resumePoint(for: video) else { return nil }
        return Float(resumePoint) / Float(video.duration)
    }
}

public protocol ResumeTimeProvider {
    func isCompleted(video: BombVideo) -> Bool
    func isResumable(video: BombVideo) -> Bool
    func progress(for video: BombVideo) -> Float?
    func resumePoint(for video: BombVideo) -> TimeInterval?
}
