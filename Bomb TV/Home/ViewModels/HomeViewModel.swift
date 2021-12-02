import AVFoundation
import BombAPI
import Foundation
import PromiseKit

class HomeViewModel {

    var defaultHighlightItem: HighlightItem?
    private let api = BombAPI()

    func fetchData() -> Guarantee<[Result<HomeSection>]>{
        return buildHomePage()
    }

    func updateHighlights() -> Promise<HomeSection> {
        return buildHighlightSection().map { HomeSection.highlight($0) }
    }

    private func buildHomePage() -> Guarantee<[Result<HomeSection>]> {
        return when(resolved: [
            buildHighlightSection().map { HomeSection.highlight($0) },
            api.videos().mapValues { $0.viewModel(api: self.api) }.map { HomeSection.videoRow("Latest", $0) },
            api.getShows().filterValues { $0.isPromoted }.map { shows -> [Show] in
                return shows.sorted { (lhs, rhs) -> Bool in
                    lhs.position < rhs.position
                }
            }.map { HomeSection.shows($0) },
            api.getRecentlyWatched().mapValues { $0.viewModel(api: self.api) }.map { HomeSection.videoRow("Continue watching", $0) },
            getQuickLooks().map { HomeSection.videoRow("Quick Looks", $0) },
            getTenYearsAgoVideos().map { HomeSection.videoRow("Ten years ago…", $0) }
        ])
    }

    private func getQuickLooks() -> Promise<[VideoViewModel]> {
        let filter = VideoFilter.keyShow(.quickLooks)
        return api.videos(filter: filter)
            .mapValues { $0.viewModel(api: self.api) }
    }

    private func getTenYearsAgoVideos() -> Promise<[VideoViewModel]> {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        guard let weekDate = calendar.date(from: components),
            let tenYearsAgo = calendar.date(byAdding: .year, value: -10, to: weekDate),
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: tenYearsAgo) else {
                return Promise(error: HomeViewModelError.invalidDate)
        }
        let filter = VideoFilter.date(start: tenYearsAgo, end: endOfWeek)
        return api.videos(filter: filter)
            .mapValues { $0.viewModel(api: self.api) }
    }

    private func buildHighlightSection() -> Promise<[HighlightItem]> {
        return when(fulfilled: [
            getLiveVideoItem(),
            api.getRecentlyWatched(limit: 3)
                .mapValues { $0.viewModel(api: self.api) }
                .mapValues { HighlightItem.resumeWatching($0) },
            api.videos(limit: 1)
                .mapValues { $0.viewModel(api: self.api) }
                .mapValues { HighlightItem.latest($0) }
        ]).map { parts in
            return Array(parts.joined())
        }.get { array in
            self.defaultHighlightItem = array.first
        }
    }

    private func getLiveVideoItem() -> Promise<[HighlightItem]> {
        return firstly {
            api.liveVideo()
        }.map { video in
            [HighlightItem.liveStream(video)]
        }.recover { error -> Promise<[HighlightItem]> in
            if case BombAPIError.noLiveVideos = error {
                return .value([])
            }
            throw error
        }
    }
}

enum HomeViewModelError: Error {
    case invalidDate
}
