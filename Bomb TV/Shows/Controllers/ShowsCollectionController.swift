import BombAPI
import PromiseKit
import UIKit

class ShowsCollectionController: UIViewController {

    @IBOutlet private var backgroundImageView: UIImageView!
    @IBOutlet private var showSelectionTableView: UITableView!
    @IBOutlet private var showDetailsCollectionView: UICollectionView!

    private lazy var showSelectionDataSource: UITableViewDiffableDataSource<ShowsListSection, Show> = {
        return UITableViewDiffableDataSource<ShowsListSection, Show>(tableView: self.showSelectionTableView)
        { (tableView, indexPath, show) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: "ShowListCell", for: indexPath)
            cell.textLabel?.text = show.title
            cell.detailTextLabel?.text = show.showDescription
            cell.detailTextLabel?.enablesMarqueeWhenAncestorFocused = true
            return cell
        }
    }()

    private lazy var showDataSource: UICollectionViewDiffableDataSource<ShowSection, BombVideo> = {
        return UICollectionViewDiffableDataSource<ShowSection, BombVideo>(collectionView: self.showDetailsCollectionView)
        { (collectionView, indexPath, video) -> UICollectionViewCell? in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCell.reuseIdentifier, for: indexPath) as? VideoCell else {
                return nil
            }
            cell.alwaysShowsTitles = true
            cell.video = .video(video)
            return cell
        }
    }()

    private let viewModel = ShowsCollectionViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        showSelectionTableView.dataSource = showSelectionDataSource
        showSelectionTableView.delegate = self

        showDetailsCollectionView.register(UINib(nibName: "VideoCell", bundle: nil),
                                           forCellWithReuseIdentifier: VideoCell.reuseIdentifier)
        showDetailsCollectionView.dataSource = showDataSource
        showDetailsCollectionView.delegate = self

        firstly {
            viewModel.fetchShowList()
        }.done { results in
            var snapshot = NSDiffableDataSourceSnapshot<ShowsListSection, Show>()
            snapshot.appendSections([.show])
            snapshot.appendItems(results)
            self.showSelectionDataSource.apply(snapshot, animatingDifferences: true)
            self.showSelectionTableView.setNeedsFocusUpdate()
        }.catch { error in
            print(error.localizedDescription)
        }
    }
}

extension ShowsCollectionController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width / 2, height: collectionView.frame.size.width / 2.5)
    }
}

extension ShowsCollectionController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        print("focus")

        guard let indexPath = context.nextFocusedIndexPath,
            let show = showSelectionDataSource.itemIdentifier(for: indexPath) else { return }

        firstly {
            viewModel.fetchVideos(for: show)
        }.done { results in
            var snapshot = NSDiffableDataSourceSnapshot<ShowSection, BombVideo>()
            snapshot.appendSections([.videos])
            snapshot.appendItems(results)
            self.showDataSource.apply(snapshot, animatingDifferences: true)
        }.catch { error in
            print(error.localizedDescription)
        }
    }
}

enum ShowsListSection {
    case show
}

class ShowsCollectionViewModel {
    private let api = BombAPI()
    private var pendingShowRequest: Show?

    func fetchShowList() -> Promise<[Show]> {
        return api.getShows()
    }

    func fetchVideos(for show: Show) -> Promise<[BombVideo]> {
        let waitAtLeast = after(seconds: 0.3)
        let filter = VideoFilter.show(show)
        pendingShowRequest = show

        return firstly {
            waitAtLeast
        }.then { () -> Promise<[BombVideo]> in
            guard show == self.pendingShowRequest else {
                throw ShowsError.superceded
            }
            return self.api.recentVideos(filter: filter)
        }
    }
}

enum ShowsError: Error {
    case superceded
}
