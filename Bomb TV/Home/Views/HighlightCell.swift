import Nuke
import UIKit

class HighlightCell: UICollectionViewCell {
    @IBOutlet private var mainImageView: UIImageView!
    @IBOutlet weak var imageWidthAnchor: NSLayoutConstraint!
    @IBOutlet weak var imageHeightAnchor: NSLayoutConstraint!
    
    var item: HighlightItem? {
        didSet {
            guard let item = item else {
                prepareForReuse()
                return
            }

            Nuke.loadImage(with: item.previewImage, into: mainImageView)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        mainImageView.adjustsImageWhenAncestorFocused = true
//        mainImageView.focusedFrameGuide
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if context.nextFocusedView == self {
            clipsToBounds = false
            coordinator.addCoordinatedFocusingAnimations({ animationContext in
//                let frame = self.frame
//                self.frame = CGRect(x: frame.minX, y: frame.minY, width: 1200, height: frame.height)
//                self.imageWidthAnchor.constant = 1200
//                self.layoutIfNeeded()
            }, completion: {
                // Nothing
            })
        } else {
            clipsToBounds = true
            coordinator.addCoordinatedUnfocusingAnimations({ animationContext in
//                self.imageWidthAnchor.constant = 600
//                let frame = self.frame
//                self.frame = CGRect(x: frame.minX, y: frame.minY, width: 600, height: frame.height)
//                self.layoutIfNeeded()
            }, completion: {
                // Nothing yet
            })
        }
    }
}
