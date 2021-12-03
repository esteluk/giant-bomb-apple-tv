import BombAPI
import Nuke
import UIKit

class SingleShowController: UIViewController {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var showImageView: UIImageView!
    @IBOutlet private var bottomBackgroundArea: UIVisualEffectView!
    @IBOutlet private var showsCollectionView: UICollectionView!

    private lazy var dataSource: UICollectionViewDiffableDataSource<ShowSection, VideoViewModel> = {
        return UICollectionViewDiffableDataSource<ShowSection, VideoViewModel>(collectionView: self.showsCollectionView)
        { (collectionView, indexPath, video) -> UICollectionViewCell? in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCell.reuseIdentifier, for: indexPath) as? VideoCell else {
                preconditionFailure()
            }
            cell.alwaysShowsTitles = true
            cell.video = HomeScreenItem.video(video)
            return cell
        }
    }()

    var coordinator: HomeCoordinator?
    var show: Show? {
        didSet {
            guard let show = show else { return }
            viewModel = SingleShowViewModel(show: show)
        }
    }
    private var viewModel: SingleShowViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()

        bottomBackgroundArea.isHidden = true
        showsCollectionView.dataSource = dataSource
        showsCollectionView.delegate = self
        showsCollectionView.register(UINib(nibName: "VideoCell", bundle: nil),
                                     forCellWithReuseIdentifier: VideoCell.reuseIdentifier)

        guard let show = show, let viewModel = viewModel else { return }
        titleLabel.text = show.title
        descriptionLabel.text = show.showDescription
        Nuke.loadImage(with: show.images.super, into: showImageView)

        Task {
            let videos = try await viewModel.fetchData()
            var snapshot = NSDiffableDataSourceSnapshot<ShowSection, VideoViewModel>()
            snapshot.appendSections([.videos])
            snapshot.appendItems(videos)
            await dataSource.apply(snapshot, animatingDifferences: true)
            bottomBackgroundArea.isHidden = false
            showsCollectionView.setNeedsFocusUpdate()
        }
    }

    @IBAction private func playLatestAction(_ sender: Any) {
        guard let video = dataSource.itemIdentifier(for: IndexPath(row: 0, section: 0)) else { return }
        coordinator?.playVideo(video: video)
    }
    
}

extension SingleShowController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let video = dataSource.itemIdentifier(for: indexPath) else { return }
        coordinator?.playVideo(video: video)
    }
}

extension SingleShowController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width / 5, height: collectionView.frame.height * 0.8)
    }
}

enum ShowSection {
    case videos
}

class SingleShowViewModel {
    private let api = BombAPI()
    private let show: Show

    init(show: Show) {
        self.show = show
    }

    func fetchData() async throws -> [VideoViewModel] {
        let filter = VideoFilter.show(show)
        return try await api.videos(filter: filter)
            .map { $0.viewModel(api: api) }
    }
}
