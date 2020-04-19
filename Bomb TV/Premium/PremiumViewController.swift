import BombAPI
import PromiseKit
import UIKit

class PremiumViewController: UIViewController {
    var coordinator: PremiumCoordinator?

    @IBOutlet private var collectionView: UICollectionView!

    private lazy var dataSource: UICollectionViewDiffableDataSource<PremiumSection, VideoViewModel> = {
        return UICollectionViewDiffableDataSource<PremiumSection, VideoViewModel>(collectionView: self.collectionView)
        { (collectionView, indexPath, video) -> UICollectionViewCell? in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCell.reuseIdentifier, for: indexPath) as? VideoCell else {
                preconditionFailure()
            }
            cell.alwaysShowsTitles = true
            cell.video = HomeScreenItem.video(video)
            return cell
        }
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.numberOfLines = 0
        label.text = "Nothing here? Get access to thousands of hours of premium videos and podcasts.\n\n" +
            "Subscribe at https://giantbomb.com/premium\n\n"
        label.textColor = UIColor.secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let viewModel = PremiumViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.dataSource = dataSource
        collectionView.delegate = self
        collectionView.register(UINib(nibName: "VideoCell", bundle: nil),
                                forCellWithReuseIdentifier: VideoCell.reuseIdentifier)

        collectionView.backgroundView = emptyLabel

        firstly {
            viewModel.fetchData()
        }.done { results in
            var snapshot = NSDiffableDataSourceSnapshot<PremiumSection, VideoViewModel>()
            snapshot.appendSections([.videos])
            snapshot.appendItems(results)
            self.dataSource.apply(snapshot, animatingDifferences: false)
            self.collectionView.setNeedsFocusUpdate()
            self.emptyLabel.isHidden = results.count > 0
        }.catch { error in
            print(error.localizedDescription)
        }
    }
}

extension PremiumViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let video = dataSource.itemIdentifier(for: indexPath) else { return }
        coordinator?.playVideo(video: video)
    }
}

extension PremiumViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width / 5, height: collectionView.frame.width / 6)
    }
}

class PremiumViewModel {
    private let api = BombAPI()

    func fetchData() -> Promise<[VideoViewModel]> {
        let filter = VideoFilter.premium
        return api.videos(filter: filter).mapResumeTimes(api: api)
    }
}

enum PremiumSection {
    case videos
}
