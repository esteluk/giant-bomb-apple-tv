import AVFoundation
import BombAPI
import Foundation
import PromiseKit

class HomeViewModel {

    private let api = BombAPI()

    func fetchData() -> Guarantee<[Result<Section>]>{
        return when(resolved: [
            api.recentVideos().map { Section.latest($0) },
            api.getShows().map { Section.shows($0) }
        ])
    }

    func updatePlayedTime(video: BombVideo, duration: CMTime) {
        api.saveTime(video: video, position: Int(floor(CMTimeGetSeconds(duration))))
    }
}
