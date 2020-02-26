import AVKit
import BombAPI
import UIKit

class ViewController: UIViewController {

    private enum Constants {
        static let minimumPlayTimeBeforeSaving: Float64 = 15.0
    }

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

    private var currentlyPlaying: BombVideo?
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
                groupSize = NSCollectionLayoutSize(widthDimension: .absolute(400),
                                                   heightDimension: .absolute(300))
            case .shows:
                groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.4),
                                                   heightDimension: .fractionalWidth(0.3))
            default: fatalError()
            }

            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)

            section.interGroupSpacing = 80
            section.orthogonalScrollingBehavior = .groupPaging

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
        guard let item = dataSource.itemIdentifier(for: indexPath),
            case let .video(video) = item else { return }

        if promptToResume(video: video) == false {
            play(video: video)
        }
    }

    private func promptToResume(video: BombVideo) -> Bool {
        guard let resumePoint = video.resumePoint else { return false }
        let alert = UIAlertController(title: "Resume playback",
                                      message: "Do you want to resume from where you left off or start from the beginning of this video?",
                                      preferredStyle: .alert)

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        let timeInterval = formatter.string(from: resumePoint) ?? String(resumePoint)

        let resumeAction = UIAlertAction(title: "Resume from \(timeInterval)", style: .default) { (_) in
            self.play(video: video, resumeFromPrevious: true)
        }
        let beginningAction = UIAlertAction(title: "Restart from beginning", style: .default) { (_) in
            self.play(video: video)
        }
        alert.addAction(resumeAction)
        alert.addAction(beginningAction)
        present(alert, animated: true, completion: nil)
        return true
    }

    private func play(video: BombVideo, resumeFromPrevious: Bool = false) {
        let controller = AVPlayerViewController()
        let playerItem = AVPlayerItem(url: video.videoUrls.highQuality!)
        playerItem.externalMetadata = video.externalMetadata
        loadImage(from: video, onto: playerItem)

        if resumeFromPrevious, let resumePoint = video.resumePoint {
            playerItem.seek(to: CMTime(seconds: resumePoint, preferredTimescale: 1), completionHandler: nil)
        }

        controller.delegate = self
        controller.player = AVPlayer(playerItem: playerItem)
        currentlyPlaying = video

        present(controller, animated: true, completion: {
            controller.player?.playImmediately(atRate: 1.0)
        })
    }

    private func loadImage(from video: BombVideo, onto player: AVPlayerItem) {
        let queue = DispatchQueue(label: "videoImage", qos: .background)
        queue.async {
            guard let data = try? Data(contentsOf: video.images.small.fixed) else { return }
            let artworkData = AVMutableMetadataItem()
            artworkData.keySpace = .common
            artworkData.identifier = .commonIdentifierArtwork
            artworkData.locale = .current
            artworkData.value = data as NSCopying & NSObjectProtocol
            player.externalMetadata.append(artworkData)
        }
    }
}

extension ViewController: AVPlayerViewControllerDelegate {
    func playerViewControllerWillBeginDismissalTransition(_ playerViewController: AVPlayerViewController) {
        guard let currentlyPlaying = currentlyPlaying,
            let currentTime = playerViewController.player?.currentItem?.currentTime(),
            CMTimeGetSeconds(currentTime) > Constants.minimumPlayTimeBeforeSaving else { return }

        viewModel.updatePlayedTime(video: currentlyPlaying, duration: currentTime)
    }
}

enum Section: Hashable, Equatable {

    case highlight
    case latest([BombVideo])
    case shows([Show])
    case inProgress

    var title: String {
        switch self {
        case .highlight:
            return "Highlights"
        case .latest:
            return "Latest"
        case .shows:
            return "Shows"
        case .inProgress:
            return "Continue watching"
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .latest(let videos):
            hasher.combine(videos)
        case .shows(let shows):
            hasher.combine(shows)
        case .highlight:
            hasher.combine(3)
        case .inProgress:
            hasher.combine(4)
        }
    }

    static func == (lhs: Section, rhs: Section) -> Bool {
        switch (lhs, rhs) {
        case (.highlight, .highlight): return true
        case (.inProgress, .inProgress): return true
        case (.latest(let a), .latest(let b)): return a == b
        case (.shows(let a), .shows(let b)): return a == b
        default:
            return false
        }
    }

}

enum HomeScreenItem: Hashable {
    case video(BombVideo)
    case show(Show)
}
