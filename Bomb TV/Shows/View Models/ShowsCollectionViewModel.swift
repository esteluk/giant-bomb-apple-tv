import BombAPI
import PromiseKit

class ShowsCollectionViewModel {
    private let api = BombAPI()
    private var currentlySelectedShow: Show?

    func fetchShowList() -> Promise<[Show]> {
        return api.getShows().sortedValues()
    }

    func fetchVideos(for show: Show) -> Promise<[VideoViewModel]> {
        let waitAtLeast = after(seconds: 0.3)
        let filter = VideoFilter.show(show)
        currentlySelectedShow = show

        return firstly {
            waitAtLeast
        }.then { () -> Promise<[BombVideo]> in
            guard show == self.currentlySelectedShow else {
                throw ShowsError.superceded
            }
            return self.api.videos(filter: filter)
        }.mapValues { $0.viewModel(api: self.api) }
    }
}

enum ShowsError: Error {
    case superceded
}
