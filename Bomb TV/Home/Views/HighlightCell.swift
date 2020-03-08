import Nuke
import TVUIKit
import UIKit

class HighlightCell: UICollectionViewCell, PosterImageLoading {
    @IBOutlet private var posterView: TVPosterView!

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
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
    }
}
