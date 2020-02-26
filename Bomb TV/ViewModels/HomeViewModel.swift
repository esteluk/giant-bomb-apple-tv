import BombAPI
import PromiseKit

class HomeViewModel {
    func fetchData() -> Guarantee<[Result<Section>]>{
        let api = BombAPI()

        return when(resolved: [
            api.recentVideos().map { Section.latest($0) },
            api.getShows().map { Section.shows($0) }
        ])
    }
}
