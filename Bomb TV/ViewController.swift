import UIKit
import BombAPI

class ViewController: UIViewController {

    @IBOutlet private var collectionView: UICollectionView!

    lazy var dataSource: UICollectionViewDiffableDataSource<Section, BombVideo> = {
        let dataSource = UICollectionViewDiffableDataSource<Section, BombVideo>(collectionView: self.collectionView)
            { (collectionView: UICollectionView, indexPath: IndexPath, item: BombVideo) -> UICollectionViewCell? in
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCell.reuseIdentifier, for: indexPath) as? VideoCell else {
                    preconditionFailure()
                }

                cell.video = item
                return cell
        }

        dataSource.supplementaryViewProvider = {
            (collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? in
            if kind == UICollectionView.elementKindSectionHeader {
                guard let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionHeaderText", for: indexPath) as? SectionHeaderText else { return nil }
                view.section = .latest
                return view
            }

            return nil
        }

        return dataSource
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.register(UINib(nibName: "VideoCell", bundle: nil),
                                forCellWithReuseIdentifier: VideoCell.reuseIdentifier)
        collectionView.register(UINib(nibName: "SectionHeaderText", bundle: nil),
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SectionHeaderText")
        collectionView.dataSource = dataSource
        collectionView.delegate = self

        let api = BombAPI()
        api.recentVideos().done { videos in
            var snapshot = NSDiffableDataSourceSnapshot<Section, BombVideo>()
            snapshot.appendSections([.latest])
            snapshot.appendItems(videos)
            self.dataSource.apply(snapshot, animatingDifferences: true)

            let currentlyWatching = videos.filter { $0.resumePoint != nil }.map { $0.name }
            print(currentlyWatching)
        }.catch { error in
            print(error.localizedDescription)
        }
    }
}
extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 400, height: 300)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 100)
    }
}

enum Section {
    case latest

    var title: String {
        switch self {
        case .latest:
            return "Latest"
        }
    }
}

