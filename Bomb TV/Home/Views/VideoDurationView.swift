import BombAPI
import UIKit

class VideoDurationView: UIView {

    private static let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .caption2)
        return label
    }()

    private let premiumStar: UIImageView = {
        let view = UIImageView()
        view.contentMode = .center
        let image = UIImage(systemName: "star.fill")
        view.image = image
        view.tintColor = .black
        return view
    }()

    var video: BombVideo? {
        didSet {
            guard let video = video else {
                isHidden = true
                return
            }

            isHidden = false
            if video.duration >= 3600 {
                VideoDurationView.formatter.allowedUnits = [.hour, .minute, .second]
            } else {
                VideoDurationView.formatter.allowedUnits = [.minute, .second]
            }

            durationLabel.text = VideoDurationView.formatter.string(from: video.duration)

            if video.premium {
                backgroundColor = UIColor(named: "Premium")
                durationLabel.textColor = .black
                premiumStar.isHidden = false
            } else {
                backgroundColor = .black
                durationLabel.textColor = .white
                premiumStar.isHidden = true
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        let stack = UIStackView(arrangedSubviews: [premiumStar, durationLabel])
        stack.spacing = 4.0
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 4.0),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4.0),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4.0),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4.0)
        ])

        backgroundColor = .black
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
