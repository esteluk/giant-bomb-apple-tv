import BombAPI
import Nuke
import TVUIKit
import UIKit

class VideoCell: UICollectionViewCell, PosterImageLoading {

    @IBOutlet private var posterView: TVPosterView!

    private let completedImage = UIImageView(frame: .zero)
    private let durationView = VideoDurationView(frame: .zero)
    private let progressView = UIProgressView(progressViewStyle: .default)

    var imageTask: ImageTask?

    var alwaysShowsTitles: Bool = false {
        didSet {
            posterView.footerView?.showsOnlyWhenAncestorFocused = !alwaysShowsTitles
        }
    }

    var resumeTimeProvider: ResumeTimeProvider?

    var video: HomeScreenItem? {
        didSet {
            guard let video = video else {
                prepareForReuse()
                return
            }

            let url = video.previewImage
            posterView.title = video.title
            posterView.subtitle = nil

            imageTask = retryableImageLoad(for: url, completion: { image in
                self.posterView.image = image
            })

            completedImage.isHidden = !(video.video?.isCompleted ?? false)
            progressView.progress = video.progress ?? 0.0
            durationView.video = video.video?.video
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        posterView.footerView?.showsOnlyWhenAncestorFocused = true
        posterView.imageView.contentMode = .scaleAspectFill
        posterView.contentViewInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)

        NSLayoutConstraint.activate([
            posterView.imageView.widthAnchor.constraint(equalTo: posterView.imageView.heightAnchor, multiplier: 16/9)
        ])

        progressView.translatesAutoresizingMaskIntoConstraints = false
        durationView.translatesAutoresizingMaskIntoConstraints = false

        posterView.contentView.insertSubview(progressView, aboveSubview: posterView.imageView)
        posterView.contentView.insertSubview(durationView, aboveSubview: posterView.imageView)
        progressView.isHidden = true

        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: posterView.imageView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: posterView.imageView.trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: posterView.imageView.bottomAnchor),
            durationView.trailingAnchor.constraint(equalTo: posterView.imageView.trailingAnchor, constant: -8),
            durationView.topAnchor.constraint(equalTo: posterView.imageView.topAnchor, constant: 8)
        ])

        completedImage.translatesAutoresizingMaskIntoConstraints = false
        completedImage.image = UIImage(systemName: "checkmark.circle.fill")
        posterView.contentView.insertSubview(completedImage, aboveSubview: posterView.imageView)

        NSLayoutConstraint.activate([
            completedImage.leadingAnchor.constraint(equalTo: posterView.imageView.leadingAnchor, constant: 8),
            completedImage.topAnchor.constraint(equalTo: posterView.imageView.topAnchor, constant: 8),
            completedImage.bottomAnchor.constraint(equalTo: durationView.bottomAnchor),
            completedImage.widthAnchor.constraint(equalTo: completedImage.heightAnchor)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        posterView.title = nil
        posterView.subtitle = nil
        posterView.image = nil
        imageTask?.cancel()
        progressView.isHidden = true
        completedImage.isHidden = true
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if context.nextFocusedView == self && progressView.progress > 0 {
            progressView.isHidden = false
        } else {
            progressView.isHidden = true
        }

        if context.nextFocusedView == self {
            coordinator.addCoordinatedFocusingAnimations({ context in
                self.completedImage.transform = CGAffineTransform.identity
                    .scaledBy(x: 1.25, y: 1.25).translatedBy(x: -20, y: -12)
                self.durationView.transform = CGAffineTransform.identity
                    .scaledBy(x: 1.25, y: 1.25).translatedBy(x: 20, y: -12)
            }, completion: {
                // Nothing
            })
        } else if context.previouslyFocusedView == self {
            coordinator.addCoordinatedUnfocusingAnimations({ context in
                self.completedImage.transform = .identity
                self.durationView.transform = .identity
            }, completion: {
                // Nothing
            })
        }
    }
}

protocol PosterImageLoading: class {
    var imageTask: ImageTask? { get set }
}

extension PosterImageLoading {
    func retryableImageLoad(for url: URL, completion: @escaping ((UIImage) -> Void)) -> ImageTask {
        return ImagePipeline.shared.loadImage(with: url, completion: { result in
            switch result {
            case .success(let response):
                completion(response.image)
            case .failure(_):
                // Attempt to fix image load failure
                self.imageTask = ImagePipeline.shared.loadImage(with: url.fixed, completion: { result in
                    switch result {
                    case .success(let response):
                        completion(response.image)
                    case .failure(let error):
                        print("Failed to load image with error \(error.localizedDescription)")
                    }
                })
            }
        })
    }
}

extension UICollectionViewCell {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}
