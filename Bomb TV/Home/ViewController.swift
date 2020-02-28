import BombAPI
import UIKit

class ViewController: UIViewController {

    weak var coordinator: HomeCoordinator?

    @IBOutlet private var collectionView: UICollectionView!

    lazy var dataSource: UICollectionViewDiffableDataSource<Section, HomeScreenItem> = {
        let dataSource = UICollectionViewDiffableDataSource<Section, HomeScreenItem>(collectionView: self.collectionView)
            { (collectionView: UICollectionView, indexPath: IndexPath, item: HomeScreenItem) -> UICollectionViewCell? in
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

                let section = self.sections[indexPath.section]
                view.section = section
                return view
            }

            return nil
        }

        return dataSource
    }()

    private var sections: [Section] = []
    private let viewModel = HomeViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.register(UINib(nibName: "VideoCell", bundle: nil),
                                forCellWithReuseIdentifier: VideoCell.reuseIdentifier)
        collectionView.register(UINib(nibName: "SectionHeaderText", bundle: nil),
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SectionHeaderText")
        collectionView.dataSource = dataSource
        collectionView.delegate = self
        collectionView.collectionViewLayout = createLayout()

        viewModel.fetchData().done { results in
            var snapshot = NSDiffableDataSourceSnapshot<Section, HomeScreenItem>()
            for result in results {
                guard case let .fulfilled(value) = result else { continue }
                switch value {
                case .latest(let latestVideos):
                    snapshot.appendSections([value])
                    snapshot.appendItems(latestVideos.map { .video($0) })
                case .shows(let shows):
                    snapshot.appendSections([value])
                    snapshot.appendItems(shows.map { .show($0) })
                default: continue
                }
                self.sections.append(value)
            }

            self.dataSource.apply(snapshot, animatingDifferences: true)
            self.collectionView.setNeedsFocusUpdate()
        }.catch { error in
            print(error.localizedDescription)
        }

    }

    private func createLayout() -> UICollectionViewLayout {

        return UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            let dataSection = self.sections[sectionIndex]

            let groupSize: NSCollectionLayoutSize
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .fractionalHeight(1.0))

            switch dataSection {
            case .latest:
                groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.2),
                                                   heightDimension: .fractionalWidth(0.16))
            case .shows:
                groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.33),
                                                   heightDimension: .fractionalWidth(0.22))
            default: fatalError()
            }

            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)

            section.interGroupSpacing = 0
            section.orthogonalScrollingBehavior = .continuous

            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(132)),
                                                                     elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
            header.pinToVisibleBounds = false
            section.boundarySupplementaryItems = [header]
            return section
        }
    }

}
extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .show(let show):
            coordinator?.launchShow(show: show)
        case .video(let video):
            coordinator?.playVideo(video: video)
        }
    }
}

enum HomeScreenItem: Hashable {
    case video(BombVideo)
    case show(Show)
}
