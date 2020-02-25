import UIKit
import BombAPI

class ViewController: UIViewController {

    @IBOutlet private var collectionView: UICollectionView!

    lazy var dataSource = {
        return UICollectionViewDiffableDataSource<Section, BombVideo>(collectionView: self.collectionView)
            { (collectionView: UICollectionView, indexPath: IndexPath, item: BombVideo) -> UICollectionViewCell? in
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCell.reuseIdentifier, for: indexPath) as? VideoCell else {
                    preconditionFailure()
                }

                cell.video = item
                return cell
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        collectionView.register(UINib(nibName: "VideoCell", bundle: nil),
                                forCellWithReuseIdentifier: VideoCell.reuseIdentifier)
        collectionView.dataSource = dataSource

        let api = BombAPI()
        api.recentVideos().done { videos in
            var snapshot = NSDiffableDataSourceSnapshot<Section, BombVideo>()
            snapshot.appendSections([.latest])
            snapshot.appendItems(videos)
            self.dataSource.apply(snapshot, animatingDifferences: true)

            let currentlyWatching = videos.filter { $0.}
        }.catch { error in
            print(error.localizedDescription)
        }
    }

}

enum Section {
    case latest
}

