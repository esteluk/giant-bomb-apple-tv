import AVKit
import BombAPI
import UIKit


class VideoCoordinator: NSObject, DestinationCoordinator {

    private enum Constants {
        static let minimumPlayTimeBeforeSaving: Float64 = 15.0
    }

    private let video: BombVideo
    var coordinator: NavigationCoordinator?
    var rootController: UIViewController

    init(video: BombVideo, presentingController: UIViewController) {
        self.rootController = presentingController
        self.video = video
    }

    func start() {
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
        rootController.present(alert, animated: true, completion: nil)
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

        rootController.present(controller, animated: true, completion: {
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

extension VideoCoordinator: AVPlayerViewControllerDelegate {
    func playerViewControllerWillBeginDismissalTransition(_ playerViewController: AVPlayerViewController) {
        guard let currentTime = playerViewController.player?.currentItem?.currentTime(),
            CMTimeGetSeconds(currentTime) > Constants.minimumPlayTimeBeforeSaving else { return }

        updatePlayedTime(duration: currentTime)
    }

    private func updatePlayedTime(duration: CMTime) {
        let api = BombAPI()
        _ = api.saveTime(video: video, position: Int(floor(CMTimeGetSeconds(duration)))).ensure {
            self.coordinator?.childDidFinish(self)
        }
    }
}

protocol VideoPresenting: NavigationCoordinator {}

extension VideoPresenting {
    func playVideo(video: BombVideo) {
        let coordinator = VideoCoordinator(video: video, presentingController: navigationController)
        coordinator.coordinator = self
        coordinator.start()
        childCoordinators.append(coordinator)
    }
}
