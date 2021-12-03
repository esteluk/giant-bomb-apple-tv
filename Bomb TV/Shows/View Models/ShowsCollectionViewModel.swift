import BombAPI
import Foundation

class ShowsCollectionViewModel {
    private let api = BombAPI()
    private var currentlySelectedShow: Show?

    func fetchShowList() async throws -> [Show] {
        return try await api.getShows().sorted()
    }

    func fetchVideos(for show: Show) async throws -> [VideoViewModel] {
        await Task.sleep(UInt64(0.3 * Double(NSEC_PER_SEC)))
        let filter = VideoFilter.show(show)
        currentlySelectedShow = show

        guard show == self.currentlySelectedShow else {
            throw ShowsError.superceded
        }

        return try await api.videos(filter: filter)
            .map { $0.viewModel(api: api) }
    }
}

enum ShowsError: Error {
    case superceded
}
