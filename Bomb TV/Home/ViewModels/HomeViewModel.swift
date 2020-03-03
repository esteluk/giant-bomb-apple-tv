import AVFoundation
import BombAPI
import Foundation
import PromiseKit

class HomeViewModel {

    private let api = BombAPI()

    func fetchData() -> Guarantee<[Result<HomeSection>]>{
        return when(resolved: [
            buildHighlightSection().map { HomeSection.highlight($0) },
            api.recentVideos().map { HomeSection.latest($0) },
            api.getShows().map { HomeSection.shows($0) }
        ])
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
