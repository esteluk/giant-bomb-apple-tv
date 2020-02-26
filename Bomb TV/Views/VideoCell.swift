import BombAPI
import Nuke
import TVUIKit
import UIKit

class VideoCell: UICollectionViewCell {

    @IBOutlet private var posterView: TVPosterView!

    var video: HomeScreenItem? {
        didSet {
            guard let video = video else {
                prepareForReuse()
                return
            }

            switch video {
            case .show(let show):
                Nuke.loadImage(with: show.images.medium.fixed, into: posterView.imageView)
                posterView.title = show.title
            case .video(let video):
                Nuke.loadImage(with: video.images.super.fixed, into: posterView.imageView)
                posterView.title = video.name
            }

            posterView.subtitle = nil
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        posterView.title = nil
        posterView.subtitle = nil
        posterView.image = nil
    }
}

extension UICollectionViewCell {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}
