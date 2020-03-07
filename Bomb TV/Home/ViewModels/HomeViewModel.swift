import AVFoundation
import BombAPI
import Foundation
import PromiseKit

class HomeViewModel {

    private let api = BombAPI()

    func fetchData() -> Guarantee<[Result<HomeSection>]>{
        return when(resolved: [
            buildHighlightSection().map { HomeSection.highlight($0) },
            api.recentVideos().map { HomeSection.videoRow("Latest", $0) },
            api.getShows().map { HomeSection.shows($0) },
            getQuickLooks().map { HomeSection.videoRow("Quick Looks", $0) },
            getTenYearsAgoVideos().map { HomeSection.videoRow("Ten years ago…", $0) }
        ])
    }

    private func getQuickLooks() -> Promise<[BombVideo]> {
        let filter = VideoFilter.keyShow(.quickLooks)
        return api.recentVideos(filter: filter)
    }

    private func getTenYearsAgoVideos() -> Promise<[BombVideo]> {
        let calendar = Calendar.current
        guard let tenYearsAgo = calendar.date(byAdding: .year, value: -10, to: Date()),
            let startOfWeek = calendar.date(bySetting: .weekday, value: 1, of: tenYearsAgo),
            let endOfWeek = calendar.date(bySetting: .weekday, value: 7, of: tenYearsAgo) else {
                return Promise(error: HomeViewModelError.invalidDate)
        }
        let filter = VideoFilter.date(start: startOfWeek, end: endOfWeek)
        return api.recentVideos(filter: filter)
    }

    private func buildHighlightSection() -> Promise<[HighlightItem]> {
        return when(fulfilled: [
            getLiveVideoItem(),
            api.getRecentlyWatched(limit: 3).mapValues { HighlightItem.resumeWatching($0) }
        ]).map { parts in
            return Array(parts.joined())
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
