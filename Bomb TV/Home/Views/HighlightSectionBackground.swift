import Nuke
import UIKit

class HighlightSectionBackground: UICollectionReusableView {

    static let kind = "highlightBackground"

    var highlightItem: HighlightItem? {
        didSet {
            guard let highlightItem = highlightItem else {
                return
            }

            var options = ImageLoadingOptions(
                placeholder: imageView.image,
                transition: .fadeIn(duration: 1.0),
                contentModes: .init(success: .center, failure: .center, placeholder: .center)
            )
            options.alwaysTransition = true

            func request(for url: URL) -> ImageRequest {
                let upsize = imageView.bounds.size.applying(CGAffineTransform(scaleX: 1.05, y: 1.05))
                return ImageRequest(
                    url: url,
                    processors: [
                        ImageProcessors.Resize(size: upsize, crop: true, upscale: true),
                        ImageProcessors.GaussianBlur(),
                        ImageProcessors.CoreImageFilter(name: "CIExposureAdjust", parameters: [kCIInputEVKey: NSNumber(-2.0)], identifier: "exposure")
                    ]
                )
            }

            Nuke.loadImage(with: request(for: highlightItem.previewImage),
                           options: options,
                           into: imageView, progress: nil) { result in
                switch result {
                case .failure:
                    Nuke.loadImage(with: request(for: highlightItem.previewImage.fixed),
                                   options: options,
                                   into: self.imageView)
                default:
                    break
                }
            }

            if titleLabel.isHidden {
                titleLabel.text = highlightItem.prompt
            } else {
                UIView.transition(with: titleLabel,
                                  duration: 1.0,
                                  options: .transitionCrossDissolve,
                                  animations: {
                                    self.titleLabel.text = highlightItem.prompt
                }, completion: nil)
            }
        }
    }

    var isItemFocused: Bool = false {
        didSet {
            let shouldAnimate = isItemFocused == titleLabel.isHidden
            guard shouldAnimate else { return }

            if titleLabel.isHidden {
                // Animate appearing
                titleLabel.alpha = 0.0
                titleLabel.isHidden = false
                UIView.animate(withDuration: 0.3) {
                    self.titleLabel.alpha = 1.0
                }
            } else {
                // Animate disappearing
                titleLabel.alpha = 1.0
                UIView.animate(withDuration: 0.3, animations: {
                    self.titleLabel.alpha = 0.0
                }) { _ in
                    self.titleLabel.isHidden = true
                }
            }
        }
    }

    private var imageView: UIImageView
    private var titleLabel: UILabel

    override init(frame: CGRect) {
        imageView = UIImageView(frame: frame)
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill

        titleLabel = UILabel(frame: frame)
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.isHidden = true
        titleLabel.textColor = .white

        super.init(frame: frame)
        backgroundColor = .systemGray

        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(imageView)
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 40),
            titleLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -360)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
