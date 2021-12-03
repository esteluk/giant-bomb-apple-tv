
import Foundation

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

    public func prefetch() async throws {
        async let videos = try await videos()
        async let recentlyWatched = try await getRecentlyWatched()
        _ = try await [videos, recentlyWatched]
        return
    }

    /// Gets an array of all the Show objects that are available within the API. Examples of "Show" objects
    /// are "Quick Looks", "Unprofessional Fridays" or "Mass Alex"
    /// - Returns: A promise for an array of Shows
    public func getShows() async throws -> [Show] {
        let queryItems = [
            URLQueryItem(name: "field_list", value: Show.fields)
        ]
        let request = buildRequest(for: "video_shows", queryItems: queryItems)

        let (data, _) = try await session.data(for: request, delegate: nil)
        let shows = try decoder.decode(WrappedResponse<[Show]>.self, from: data).results
        shows.forEach {
            cache.storeShow($0)
        }
        return shows
    }

    /// Gets a paged list of the 100 most recent videos that are fall within the provided filter. If no filter is provided,
    /// this returns the 100 most recent videos published to the site to which the authorising user has access.
    /// - Parameters:
    ///   - filter: VideoFilter object describing which videos should be returned from this request. Defaults to nil.
    ///   - offset: If provided, the request skips the first <offset> number of results.
    /// - Returns: An array of BombVideo objects that meet the filter and offset requirements.
    public func videos(filter: VideoFilter? = nil, limit: Int? = nil, offset: Int = 0) async throws -> [BombVideo] {
        var queryItems = [
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "field_list", value: BombVideo.fields)
        ]

        if let filter = filter {
            queryItems.append(filter.queryItem)
        }

        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }

        let request = buildRequest(for: "videos", queryItems: queryItems)

        let (data, _) = try await session.data(for: request, delegate: nil)
        return try self.decoder.decode(WrappedResponse<[BombVideo]>.self, from: data).results.map { video in
            self.cache.storeVideo(video)
            return video
        }.filter {
            $0.isAvailable
        }
    }

    public func search(query: String, page: Int = 1) async throws -> WrappedResponse<[BombVideo]> {
        let queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "resources", value: "video")
        ]

        let request = buildRequest(for: "search", queryItems: queryItems)

        let (data, _) = try await session.data(for: request, delegate: nil)
        return try self.decoder.decode(WrappedResponse.self, from: data)
    }

    public func liveVideo() async throws -> LiveVideo {
        let request = buildRequest(for: "video/current-live")

        let (data, _) = try await session.data(for: request, delegate: nil)
        let response = try self.decoder.decode(LiveVideoResponse.self, from: data)
        guard let video = response.video else {
            throw BombAPIError.noLiveVideos
        }
        return video
    }

    public func getAuthenticationToken(appName: String, code: String) async throws -> AuthenticationResponse {
        let request = "https://giantbomb.com/app/\(appName)/get-result?regCode=\(code)&format=json"
        let url = URL(string: request)!

        let (data, _) = try await session.data(from: url, delegate: nil)
        return try self.decoder.decode(AuthenticationResponse.self, from: data)
    }

    public func saveTime(video: BombVideo, position: Int) async throws {
        let queryItems = [
            URLQueryItem(name: "video_id", value: String(video.id)),
            URLQueryItem(name: "time_to_save", value: String(position))
        ]
        cache.updateResumePoint(TimeInterval(position), for: video)
        let request = buildRequest(for: "video/save-time", queryItems: queryItems)

        _ = try await session.data(for: request, delegate: nil)
        return
    }

    public func markWatched(video: BombVideo) async throws {
        let queryItems = [
            URLQueryItem(name: "video_id", value: String(video.id))
        ]
        let request = buildRequest(for: "video/mark-watched", queryItems: queryItems)
        _ = try await session.data(for: request, delegate: nil)
        return
    }

    public func getRecentlyWatched(limit: Int = 100) async throws -> [BombVideo] {
        let request = buildRequest(for: "video/get-all-saved-times")

        let (data, _) = try await session.data(for: request, delegate: nil)
        let savedTimes = try decoder.decode(SavedTimesResponse.self, from: data).savedTimes.sorted()
        savedTimes.forEach { self.cache.updateResumePoint(point: $0) }

        let videoIds = savedTimes.map { $0.videoId }
        let videos = try await videos(filter: VideoFilter.videoIds(videoIds))
        let prefix = videos
            .filter { isResumable(video: $0) }
            .prefix(limit)
        return Array(prefix)
    }

    public func video(for id: Int) async throws -> BombVideo {
        if let video = cache.requestVideo(for: id) {
            return video
        }

        return try await requestVideo(for: id)
    }

    private func requestVideo(for id: Int) async throws -> BombVideo {
        let request = buildRequest(for: "video/\(String(id))")

        let (data, _) = try await session.data(for: request, delegate: nil)
        let video = try decoder.decode(WrappedResponse<BombVideo>.self, from: data).results
        self.cache.storeVideo(video)
        return video
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

extension BombAPI: ShowProvider {
    public func show(with id: Int) -> Show? {
        return cache.requestShow(for: id)
    }
}

public protocol ResumeTimeProvider {
    func isCompleted(video: BombVideo) -> Bool
    func isResumable(video: BombVideo) -> Bool
    func progress(for video: BombVideo) -> Float?
    func resumePoint(for video: BombVideo) -> TimeInterval?
}

public protocol ShowProvider {
    func show(with id: Int) -> Show?
}
