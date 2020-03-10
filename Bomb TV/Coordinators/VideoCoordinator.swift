import AVKit
import BombAPI
import UIKit

class VideoCoordinator: NSObject, DestinationCoordinator {

    private enum Constants {
        static let minimumPlayTimeBeforeSaving: Float64 = 15.0
    }

    private let launchDirectly: Bool
    private let video: BombVideo
    var coordinator: NavigationCoordinator?
    var rootController: UIViewController

    init(video: BombVideo, launchDirectly: Bool, presentingController: UIViewController) {
        self.launchDirectly = launchDirectly
        self.rootController = presentingController
        self.video = video
    }

    func start() {
        if launchDirectly {
            play(video: video, resumeFromPrevious: true)
            return
        }

        if promptToResume(video: video) == false {
            play(video: video)
        }
    }

    private func promptToResume(video: BombVideo) -> Bool {
        guard launchDirectly == false,
            let resumePoint = video.resumePoint else { return false }
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
        let quality = SettingsBundleHelper().selectedVideoQuality
        let playerItem = AVPlayerItem(url: video.videoUrls.url(for: quality)!)
        playerItem.externalMetadata = video.externalMetadata
        VideoCoordinator.loadImage(from: video.images.small.fixed, onto: playerItem)

        if resumeFromPrevious, let resumePoint = video.resumePoint {
            playerItem.seek(to: CMTime(seconds: resumePoint, preferredTimescale: 1), completionHandler: nil)
        }

        controller.delegate = self
        controller.player = AVPlayer(playerItem: playerItem)

        let secondsTimescale = CMTimeScale(NSEC_PER_SEC)
        let updateInterval = CMTime(seconds: 60, preferredTimescale: secondsTimescale)

        controller.player?.addPeriodicTimeObserver(forInterval: updateInterval, queue: .main, using: { time in
            self.updatePlayedTime(duration: time)
        })

        rootController.present(controller, animated: true, completion: {
            controller.player?.playImmediately(atRate: 1.0)
        })
    }

    fileprivate static func loadImage(from url: URL, onto player: AVPlayerItem) {
        let queue = DispatchQueue(label: "videoImage", qos: .background)
        queue.async {
            guard let data = try? Data(contentsOf: url) else { return }
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

class LiveVideoCoordinator: NSObject, DestinationCoordinator {

    private let video: LiveVideo
    var coordinator: NavigationCoordinator?
    var rootController: UIViewController

    init(liveVideo: LiveVideo, coordinator: NavigationCoordinator, presentingController: UIViewController) {
        self.coordinator = coordinator
        self.video = liveVideo
        self.rootController = presentingController
    }

    func start() {
        let controller = AVPlayerViewController()
        let playerItem = AVPlayerItem(url: video.stream)
        playerItem.externalMetadata = video.externalMetadata
        VideoCoordinator.loadImage(from: video.image, onto: playerItem)

        controller.player = AVPlayer(playerItem: playerItem)

        rootController.present(controller, animated: true, completion: {
            controller.player?.playImmediately(atRate: 1.0)
        })
    }
}

protocol VideoPresenting: NavigationCoordinator {}

extension VideoPresenting {
    func play(liveVideo: LiveVideo) {
        let coordinator = LiveVideoCoordinator(liveVideo: liveVideo,
                                               coordinator: self,
                                               presentingController: navigationController)
        coordinator.start()
        childCoordinators.append(coordinator)
    }

    func playVideo(video: BombVideo, launchDirectly: Bool = false) {
        let coordinator = VideoCoordinator(video: video,
                                           launchDirectly: launchDirectly,
                                           presentingController: navigationController)
        coordinator.coordinator = self
        coordinator.start()
        childCoordinators.append(coordinator)
    }
}

class SettingsBundleHelper {
    enum Keys {
        static let videoQuality = "video_quality"
    }

    enum VideoQualityOptions: String {
        case low
        case high
        case hd
    }

    var selectedVideoQuality: VideoQualityOptions {
        let defaults = UserDefaults.standard
        guard let value = defaults.string(forKey: Keys.videoQuality),
            let quality = VideoQualityOptions(rawValue: value) else { return .hd }
        return  quality
    }
}

extension VideoUrls {
    func url(for quality: SettingsBundleHelper.VideoQualityOptions) -> URL? {
        switch quality {
        case .low: return lowQuality
        case .high: return mediumQuality
        case .hd: return highQuality
        }
    }
}
