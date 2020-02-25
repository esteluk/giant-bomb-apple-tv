import BombAPI
import Nuke
import UIKit

class VideoCell: UICollectionViewCell {

    @IBOutlet private var thumbnailView: UIImageView!

    var video: BombVideo? {
        didSet {
            guard let video = video else {
                prepareForReuse()
                return
            }
            Nuke.loadImage(with: video.images.small, into: thumbnailView)
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
