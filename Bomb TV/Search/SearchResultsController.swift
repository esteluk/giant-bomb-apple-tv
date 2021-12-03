import BombAPI
import UIKit

class SearchResultsController: UIViewController {
    var coordinator: SearchCoordinator?
    private let viewModel = SearchViewModel()

    private lazy var dataSource: UICollectionViewDiffableDataSource<SearchSection, VideoViewModel> = {
        return UICollectionViewDiffableDataSource<SearchSection, VideoViewModel>(collectionView: self.collectionView)
        { (collectionView, indexPath, video) -> UICollectionViewCell? in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCell.reuseIdentifier, for: indexPath) as? VideoCell else {
                preconditionFailure()
            }
            cell.alwaysShowsTitles = true
            cell.video = HomeScreenItem.video(video)
            return cell
        }
    }()

    @IBOutlet private var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.dataSource = dataSource
        collectionView.delegate = self
        collectionView.register(UINib(nibName: "VideoCell", bundle: nil),
                                forCellWithReuseIdentifier: VideoCell.reuseIdentifier)
    }
}

extension SearchResultsController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let video = dataSource.itemIdentifier(for: indexPath) else { return }
        coordinator?.playVideo(video: video)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard viewModel.isLastIndexPath(indexPath) else { return }

        Task {
            let results = try await viewModel.requestMoreResults()
            var snapshot = self.dataSource.snapshot()
            snapshot.appendItems(results)
            await self.dataSource.apply(snapshot)
        }
    }
}

extension SearchResultsController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width / 4, height: collectionView.frame.width / 5)
    }
}

extension SearchResultsController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text else {
            var snapshot = dataSource.snapshot()
            snapshot.deleteAllItems()
            dataSource.apply(snapshot)
            return
        }

        Task {
            let results = try await viewModel.performSearch(query: query)
            var snapshot = NSDiffableDataSourceSnapshot<SearchSection, VideoViewModel>()
            snapshot.appendSections([.videos])
            snapshot.appendItems(results)
            await dataSource.apply(snapshot, animatingDifferences: true)
            collectionView.setNeedsFocusUpdate()
        }
    }
}

enum SearchSection {
    case videos
}

class SearchViewModel {
    private let api = BombAPI()
    private var isMakingRequest: Bool = false
    private var page: Int = 1
    private var query: String?
    private var searchResponse: WrappedResponse<[BombVideo]>?
    private var videos = [BombVideo]()

    func isLastIndexPath(_ indexPath: IndexPath) -> Bool {
        return indexPath.row == (videos.endIndex - 1)
    }

    func performSearch(query: String) async throws -> [VideoViewModel] {
        defer {
            // TODO
            self.isMakingRequest = false
        }
        guard query != self.query else {
            throw SearchError.pendingSearchResult
        }

        self.page = 1
        self.query = query
        videos = []
        isMakingRequest = true

        let response = try await api.search(query: query)
        guard query == self.query else { throw SearchError.supercededResult }
        self.searchResponse = response
        self.videos = response.results

        return videos.map { $0.viewModel(api: api) }
    }

    func requestMoreResults() async throws -> [VideoViewModel] {
        // TODO: is making request
        guard isMakingRequest == false,
            let searchResponse = searchResponse,
            let query = query else {
            throw SearchError.pendingSearchResult
        }
        guard videos.count < searchResponse.numberOfTotalResults else {
            throw SearchError.noMoreResults
        }
        isMakingRequest = true
        page += 1

        let response = try await api.search(query: query, page: page)
        self.searchResponse = response
        let results = response.results
        self.videos.append(contentsOf: results)
        return results.map { $0.viewModel(api: api) }
    }
}

enum SearchError: Error {
    case noMoreResults
    case pendingSearchResult
    case supercededResult
}
