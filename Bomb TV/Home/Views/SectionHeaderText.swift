import UIKit

class SectionHeaderText: UICollectionReusableView {
    @IBOutlet private var titleLabel: UILabel!

    var section: HomeSection? {
        didSet {
            guard let section = section else {
                prepareForReuse()
                return
            }
            titleLabel.text = section.title
        }
    }

    override func prepareForReuse() {
        titleLabel.text = nil
        super.prepareForReuse()
    }

}
