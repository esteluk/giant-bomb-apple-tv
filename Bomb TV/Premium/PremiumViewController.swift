import BombAPI
import PromiseKit
import UIKit

class PremiumViewController: UIViewController {
    var coordinator: PremiumCoordinator?

    @IBOutlet private var collectionView: UICollectionView!

    private lazy var dataSource: UICollectionViewDiffableDataSource<PremiumSection, BombVideo> = {
        return UICollectionViewDiffableDataSource<PremiumSection, BombVideo>(collectionView: self.collectionView)
        { (collectionView, indexPath, video) -> UICollectionViewCell? in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCell.reuseIdentifier, for: indexPath) as? VideoCell else {
                preconditionFailure()
            }
            cell.alwaysShowsTitles = true
            cell.video = HomeScreenItem.video(video)
            return cell
        }
    }()

    private let viewModel = PremiumViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.dataSource = dataSource
        collectionView.delegate = self
        collectionView.register(UINib(nibName: "VideoCell", bundle: nil),
                                forCellWithReuseIdentifier: VideoCell.reuseIdentifier)

        firstly {
            viewModel.fetchData()
        }.done { results in
            var snapshot = NSDiffableDataSourceSnapshot<PremiumSection, BombVideo>()
            snapshot.appendSections([.videos])
            snapshot.appendItems(results)
            self.dataSource.apply(snapshot, animatingDifferences: false)
            self.collectionView.setNeedsFocusUpdate()
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

    func fetchData() -> Promise<[BombVideo]> {
        let filter = VideoFilter.premium
        return api.recentVideos(filter: filter)
    }
}

enum PremiumSection {
    case videos
}
