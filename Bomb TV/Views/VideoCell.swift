import BombAPI
import Nuke
import TVUIKit
import UIKit

class VideoCell: UICollectionViewCell {

    @IBOutlet private var posterView: TVPosterView!

    var video: BombVideo? {
        didSet {
            guard let video = video else {
                prepareForReuse()
                return
            }
            Nuke.loadImage(with: video.images.small.fixed, into: posterView.imageView)
            posterView.title = video.name
            posterView.subtitle = nil
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }
}

extension UICollectionViewCell {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}
