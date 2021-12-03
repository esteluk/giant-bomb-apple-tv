import AVFoundation
import BombAPI
import Foundation

class HomeViewModel {

    var defaultHighlightItem: HighlightItem?
    private let api = BombAPI()

    func fetchData() async throws -> [HomeSection] {
        return try await buildHomePage()
    }

    func updateHighlights() async throws -> HomeSection {
        let section = try await buildHighlightSection()
        return HomeSection.highlight(section)
    }

    private func buildHomePage() async throws -> [HomeSection] {

        async let highlight = try await buildHighlightSection()
        async let videos = try await api.videos()
            .map { $0.viewModel(api: api) }
        async let shows = try await api.getShows()
            .filter { $0.isPromoted }
            .sorted { $0.position < $1.position }

        async let recentlyWatched = try await api.getRecentlyWatched()
            .map { $0.viewModel(api: api) }

        async let quickLooks = try await getQuickLooks()

        async let tenYears = try await getTenYearsAgoVideos()

        return try await [
            HomeSection.highlight(highlight),
            HomeSection.videoRow("Latest", videos),
            HomeSection.shows(shows),
            HomeSection.videoRow("Continue watching", recentlyWatched),
            HomeSection.videoRow("Quick Looks", quickLooks),
            HomeSection.videoRow("Ten years ago…", tenYears)
        ]
    }

    private func getQuickLooks() async throws -> [VideoViewModel] {
        let filter = VideoFilter.keyShow(.quickLooks)
        return try await api.videos(filter: filter)
            .map { $0.viewModel(api: api) }
    }

    private func getTenYearsAgoVideos() async throws -> [VideoViewModel] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        guard let weekDate = calendar.date(from: components),
            let tenYearsAgo = calendar.date(byAdding: .year, value: -10, to: weekDate),
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: tenYearsAgo) else {
                throw HomeViewModelError.invalidDate
        }
        let filter = VideoFilter.date(start: tenYearsAgo, end: endOfWeek)
        return try await api.videos(filter: filter)
            .map { $0.viewModel(api: api) }
    }

    private func buildHighlightSection() async throws -> [HighlightItem] {
        async let liveVideo = await getLiveVideoItems()
        async let recentlyWatched = try await api.getRecentlyWatched()
            .map { $0.viewModel(api: api) }
            .map { HighlightItem.resumeWatching($0) }
        async let videos = try await api.videos(limit: 1)
            .map { $0.viewModel(api: api) }
            .map { HighlightItem.resumeWatching($0) }

        let images = try await [liveVideo, recentlyWatched, videos].joined()
        defaultHighlightItem = images.first
        return Array(images)
    }

    private func getLiveVideoItems() async -> [HighlightItem] {
        do {
            let video = try await api.liveVideo()
            return [HighlightItem.liveStream(video)]
        } catch {
            return []
        }
    }
}

enum HomeViewModelError: Error {
    case invalidDate
}
