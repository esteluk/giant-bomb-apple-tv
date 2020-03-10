import Nuke
import TVUIKit
import UIKit

class HighlightCell: UICollectionViewCell, PosterImageLoading {
    @IBOutlet private var posterView: TVPosterView!

    private let progressView = UIProgressView(progressViewStyle: .default)

    var imageTask: ImageTask?

    var item: HighlightItem? {
        didSet {
            guard let item = item else {
                prepareForReuse()
                return
            }

            imageTask = retryableImageLoad(for: item.previewImage, completion: { image in
                self.posterView.image = image
            })

            progressView.progress = item.progress ?? 0.0
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        posterView.contentView.insertSubview(progressView, aboveSubview: posterView.imageView)
        progressView.isHidden = true

        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: posterView.imageView.leadingAnchor, constant: 0),
            progressView.trailingAnchor.constraint(equalTo: posterView.imageView.trailingAnchor, constant: 0),
            progressView.bottomAnchor.constraint(equalTo: posterView.imageView.bottomAnchor, constant: 0),
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        progressView.isHidden = true
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if context.nextFocusedView == self && progressView.progress > 0 {
            progressView.isHidden = false
        } else {
            progressView.isHidden = true
        }
    }
}
