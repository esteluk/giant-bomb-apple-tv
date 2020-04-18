import BombAPI
import UIKit

class ViewController: UIViewController {

    weak var coordinator: HomeCoordinator?
    private weak var highlightBackground: HighlightSectionBackground?

    @IBOutlet private var collectionView: UICollectionView!

    lazy var dataSource: UICollectionViewDiffableDataSource<HomeSection, HomeScreenItem> = {
        let dataSource = UICollectionViewDiffableDataSource<HomeSection, HomeScreenItem>(collectionView: self.collectionView)
            { (collectionView: UICollectionView, indexPath: IndexPath, item: HomeScreenItem) -> UICollectionViewCell? in

                switch item {
                case .highlight(let highlight):
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HighlightCell.reuseIdentifier, for: indexPath) as? HighlightCell else {
                        preconditionFailure()
                    }

                    cell.item = highlight
                    return cell
                default:
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCell.reuseIdentifier, for: indexPath) as? VideoCell else {
                        preconditionFailure()
                    }

                    cell.video = item
                    return cell
                }
        }

        dataSource.supplementaryViewProvider = {
            (collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? in
            if kind == UICollectionView.elementKindSectionHeader {
                guard let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                                 withReuseIdentifier: "SectionHeaderText",
                                                                                 for: indexPath) as? SectionHeaderText else {
                    return nil
                }

                let section = self.sections[indexPath.section]
                view.section = section
                return view
            }

            return nil
        }

        return dataSource
    }()

    private var sections: [HomeSection] = []
    private let viewModel = HomeViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.register(UINib(nibName: "VideoCell", bundle: nil),
                                forCellWithReuseIdentifier: VideoCell.reuseIdentifier)
        collectionView.register(UINib(nibName: "HighlightCell", bundle: nil),
                                forCellWithReuseIdentifier: HighlightCell.reuseIdentifier)
        collectionView.register(UINib(nibName: "SectionHeaderText", bundle: nil),
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: "SectionHeaderText")
        collectionView.dataSource = dataSource
        collectionView.delegate = self
        collectionView.collectionViewLayout = createLayout()
        collectionView.contentInset = .zero
        collectionView.contentInsetAdjustmentBehavior = .never

        viewModel.fetchData().done { results in
            var snapshot = NSDiffableDataSourceSnapshot<HomeSection, HomeScreenItem>()
            for result in results {
                guard case let .fulfilled(value) = result else { continue }
                switch value {
                case .highlight(let highlights):
                    snapshot.appendSections([value])
                    snapshot.appendItems(highlights.map { .highlight($0) })
                case .videoRow(_, let videos):
                    snapshot.appendSections([value])
                    snapshot.appendItems(videos.map { .video($0) })
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

        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            let dataSection = self.sections[sectionIndex]

            let groupSize: NSCollectionLayoutSize
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .fractionalHeight(1.0))

            switch dataSection {
            case .highlight:
                return self.layoutForHighlightSection()
            case .videoRow:
                groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.2),
                                                   heightDimension: .estimated(270))
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

            let insets = self.view.safeAreaInsets

            switch sectionIndex {
            case self.sections.endIndex-1:
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: insets.bottom, trailing: 0)
            default:
                section.contentInsets = .zero
            }

            if dataSection.hasHeader {
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                                            heightDimension: .estimated(132)),
                                                                         elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                header.pinToVisibleBounds = false
                section.boundarySupplementaryItems = [header]
            }
            return section
        }
        layout.register(HighlightSectionBackground.self, forDecorationViewOfKind: HighlightSectionBackground.kind)
        return layout
    }

    private func layoutForHighlightSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.3),
                                               heightDimension: .fractionalWidth(0.3 * (9/16)))

        let smallItem = NSCollectionLayoutItem(layoutSize: itemSize)

        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [smallItem])

        let section = NSCollectionLayoutSection(group: group)

        section.interGroupSpacing = 0
        section.orthogonalScrollingBehavior = .continuous

        let insets = self.view.safeAreaInsets
        let topMargin: CGFloat = 240

        let highlightBackground = NSCollectionLayoutDecorationItem.background(elementKind: "highlightBackground")
        highlightBackground.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: -insets.left, bottom: 0, trailing: insets.left)
        section.decorationItems = [highlightBackground]
        section.supplementariesFollowContentInsets = false
        section.contentInsets = NSDirectionalEdgeInsets(top: insets.top + topMargin, leading: 0, bottom: 50, trailing: 0)

        return section
    }
}

extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        willDisplaySupplementaryView view: UICollectionReusableView,
                        forElementKind elementKind: String,
                        at indexPath: IndexPath) {
        // Unsure if there's a better way to do this
        switch elementKind {
        case HighlightSectionBackground.kind:
            highlightBackground = view as? HighlightSectionBackground
            highlightBackground?.highlightItem = viewModel.defaultHighlightItem
        default:
            break
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        didUpdateFocusIn context: UICollectionViewFocusUpdateContext,
                        with coordinator: UIFocusAnimationCoordinator) {
        guard let nextIndexPath = context.nextFocusedIndexPath,
            let nextItem = dataSource.itemIdentifier(for: nextIndexPath) else {
                highlightBackground?.isItemFocused = false
                return
        }

        switch nextItem {
        case .highlight(let highlightItem):
            highlightBackground?.highlightItem = highlightItem
            highlightBackground?.isItemFocused = true
        default:
            highlightBackground?.isItemFocused = false
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .highlight(let highlightItem):
            switch highlightItem {
            case .latest(let viewModel):
                coordinator?.playVideo(video: viewModel, launchDirectly: true)
            case .liveStream(let liveVideo):
                coordinator?.play(liveVideo: liveVideo)
            case .resumeWatching(let viewModel):
                coordinator?.playVideo(video: viewModel, launchDirectly: true)
            }
        case .show(let show):
            coordinator?.launchShow(show: show)
        case .video(let viewModel):
            coordinator?.playVideo(video: viewModel)
        }
    }
}
