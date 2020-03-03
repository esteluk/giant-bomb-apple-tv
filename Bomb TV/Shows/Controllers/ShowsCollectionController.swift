import BombAPI
import PromiseKit
import UIKit

class ShowsCollectionController: UIViewController {

    @IBOutlet private var backgroundImageView: UIImageView!
    @IBOutlet private var showSelectionTableView: UITableView!
    @IBOutlet private var showDetailsCollectionView: UICollectionView!

    weak var coordinator: ShowsTabCoordinator?

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
        }.map { results -> Show? in
            var snapshot = NSDiffableDataSourceSnapshot<ShowsListSection, Show>()
            let primary = results.filter { $0.isVisibleInNav && $0.isActive }
            snapshot.appendSections([.active])
            snapshot.appendItems(primary)

            let inactive = results.filter { !($0.isVisibleInNav && $0.isActive) }
            snapshot.appendSections([.inactive])
            snapshot.appendItems(inactive)

            self.showSelectionDataSource.apply(snapshot, animatingDifferences: true)
            self.showSelectionTableView.setNeedsFocusUpdate()
            return primary.first
        }.done { show in
            guard let show = show else { return }
            self.loadVideos(for: show)
        }.catch { error in
            print(error.localizedDescription)
        }
    }

    private func loadVideos(for show: Show) {
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

extension ShowsCollectionController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let video = showDataSource.itemIdentifier(for: indexPath) else { return }
        coordinator?.playVideo(video: video)
    }
}

extension ShowsCollectionController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width / 2, height: collectionView.frame.size.width / 2.5)
    }
}

extension ShowsCollectionController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        guard let indexPath = context.nextFocusedIndexPath,
            let show = showSelectionDataSource.itemIdentifier(for: indexPath) else { return }

        loadVideos(for: show)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

enum ShowsListSection {
    case active
    case inactive
}
