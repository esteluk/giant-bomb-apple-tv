import BombAPI
import UIKit

class ShowListCell: UICollectionViewCell {
    @IBOutlet private var titleLabel: UILabel!

    var show: Show? {
        didSet {
            guard let show = show else {
                prepareForReuse()
                return
            }
            titleLabel.text = show.title
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
    }
}
