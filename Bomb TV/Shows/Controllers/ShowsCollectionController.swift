import BombAPI
import UIKit

class ShowsCollectionController: UIViewController {

    @IBOutlet private var backgroundImageView: UIImageView!
    @IBOutlet private var showSelectionTableView: UITableView!
    @IBOutlet private var showDetailsCollectionView: UICollectionView!

    weak var coordinator: ShowsTabCoordinator?

    private lazy var showSelectionDataSource: ShowsTableDiffableDataSource = {
        return ShowsTableDiffableDataSource(tableView: self.showSelectionTableView)
        { (tableView, indexPath, show) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: "ShowListCell", for: indexPath)
            cell.textLabel?.text = show.title
            cell.detailTextLabel?.text = show.showDescription
            cell.detailTextLabel?.enablesMarqueeWhenAncestorFocused = true
            return cell
        }
    }()

    private lazy var showDataSource: UICollectionViewDiffableDataSource<ShowSection, VideoViewModel> = {
        return UICollectionViewDiffableDataSource<ShowSection, VideoViewModel>(collectionView: self.showDetailsCollectionView)
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

        Task {
            let results = try await viewModel.fetchShowList()

            var snapshot = NSDiffableDataSourceSnapshot<ShowsListSection, Show>()
            let primary = results.filter { $0.isPromoted }
            snapshot.appendSections([.active])
            snapshot.appendItems(primary)

            let inactive = results.filter { !$0.isPromoted }
            snapshot.appendSections([.inactive])
            snapshot.appendItems(inactive)

            await showSelectionDataSource.apply(snapshot, animatingDifferences: true)
            showSelectionTableView.setNeedsFocusUpdate()

            if let show = primary.first {
                loadVideos(for: show)
            }
        }
    }

    private func loadVideos(for show: Show) {
        Task {
            let results = try await viewModel.fetchVideos(for: show)

            var snapshot = NSDiffableDataSourceSnapshot<ShowSection, VideoViewModel>()
            snapshot.appendSections([.videos])
            snapshot.appendItems(results)
             await showDataSource.apply(snapshot, animatingDifferences: true)
            showDetailsCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
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

class ShowsTableDiffableDataSource: UITableViewDiffableDataSource<ShowsListSection, Show> {
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return snapshot().sectionIdentifiers[section].title
    }
}

enum ShowsListSection {
    case active
    case inactive

    var title: String {
        switch self {
        case .active: return "Active shows"
        case .inactive: return "Inactive shows"
        }
    }
}
