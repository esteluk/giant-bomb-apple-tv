import BombAPI
import Nuke
import TVUIKit
import UIKit

class VideoCell: UICollectionViewCell {

    @IBOutlet private var posterView: TVPosterView!

    private var imageTask: ImageTask?

    var alwaysShowsTitles: Bool = false {
        didSet {
            posterView.footerView?.showsOnlyWhenAncestorFocused = !alwaysShowsTitles
        }
    }

    var video: HomeScreenItem? {
        didSet {
            guard let video = video else {
                prepareForReuse()
                return
            }

            let url: URL

            switch video {
            case .show(let show):
                url = show.images.medium.fixed
                posterView.title = show.title
            case .video(let video):
                url = video.images.super.fixed
                posterView.title = video.name
            }

            imageTask = ImagePipeline.shared.loadImage(with: url, completion: { result in
                switch result {
                case .success(let response):
                    self.posterView.image = response.image
                case .failure(let error):
                    print("Failed to load image with error \(error.localizedDescription)")
                }
            })

            posterView.subtitle = nil
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
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        posterView.title = nil
        posterView.subtitle = nil
        posterView.image = nil
        imageTask?.cancel()
    }
}

extension UICollectionViewCell {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}
