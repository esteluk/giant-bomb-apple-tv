import BombAPI
import Nuke
import TVUIKit
import UIKit

class VideoCell: UICollectionViewCell, PosterImageLoading {

    @IBOutlet private var posterView: TVPosterView!

    var imageTask: ImageTask?

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

            let url = video.previewImage
            posterView.title = video.title
            posterView.subtitle = nil

            guard imageTask?.request.urlRequest.url != url else { return }
            imageTask?.cancel()
            imageTask = retryableImageLoad(for: url, completion: { image in
                self.posterView.image = image
            })

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

protocol PosterImageLoading: class {
    var imageTask: ImageTask? { get set }
}

extension PosterImageLoading {
    func retryableImageLoad(for url: URL, completion: @escaping ((UIImage) -> Void)) -> ImageTask {
        return ImagePipeline.shared.loadImage(with: url, completion: { result in
            switch result {
            case .success(let response):
                completion(response.image)
            case .failure(_):
                // Attempt to fix image load failure
                self.imageTask = ImagePipeline.shared.loadImage(with: url.fixed, completion: { result in
                    switch result {
                    case .success(let response):
                        completion(response.image)
                    case .failure(let error):
                        print("Failed to load image with error \(error.localizedDescription)")
                    }
                })
            }
        })
    }
}

extension UICollectionViewCell {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}
