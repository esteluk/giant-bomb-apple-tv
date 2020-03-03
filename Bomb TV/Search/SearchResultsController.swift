import BombAPI
import PromiseKit
import UIKit

class SearchResultsController: UIViewController {
    var coordinator: SearchCoordinator?
    private let viewModel = SearchViewModel()

    private lazy var dataSource: UICollectionViewDiffableDataSource<SearchSection, BombVideo> = {
        return UICollectionViewDiffableDataSource<SearchSection, BombVideo>(collectionView: self.collectionView)
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
        firstly {
            self.viewModel.requestMoreResults()
        }.done { results in
            var snapshot = self.dataSource.snapshot()
            snapshot.appendItems(results)
            self.dataSource.apply(snapshot)
        }.catch { error in
            print(error.localizedDescription)
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

        firstly {
            self.viewModel.performSearch(query: query)
        }.done { results in
            var snapshot = NSDiffableDataSourceSnapshot<SearchSection, BombVideo>()
            snapshot.appendSections([.videos])
            snapshot.appendItems(results)
            self.dataSource.apply(snapshot, animatingDifferences: true)
            self.collectionView.setNeedsFocusUpdate()
        }.catch { error in
            print(error.localizedDescription)
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

    func performSearch(query: String) -> Promise<[BombVideo]> {
        guard query != self.query else {
            return Promise(error: SearchError.pendingSearchResult)
        }

        self.page = 1
        self.query = query
        videos = []
        isMakingRequest = true
        return api.search(query: query).get { response in
            guard query == self.query else { throw SearchError.supercededResult }
            self.searchResponse = response
        }.map {
            $0.results
        }.get {
            self.videos = $0
        }.ensure {
            self.isMakingRequest = false
        }
    }

    func requestMoreResults() -> Promise<[BombVideo]> {
        guard isMakingRequest == false,
            let searchResponse = searchResponse,
            let query = query else {
            return Promise(error: SearchError.pendingSearchResult)
        }
        guard videos.count < searchResponse.numberOfTotalResults else {
            return Promise(error: SearchError.noMoreResults)
        }
        isMakingRequest = true
        page += 1
        return firstly {
            api.search(query: query, page: page)
        }.get { response in
            self.searchResponse = response
        }.map {
            $0.results
        }.get {
            self.videos.append(contentsOf: $0)
        }.ensure {
            self.isMakingRequest = false
        }
    }
}

enum SearchError: Error {
    case noMoreResults
    case pendingSearchResult
    case supercededResult
}
