import UIKit

// Only really optimised to work at full screen. 1080 height. Who knows.
class ExcitingBackgroundView: UIView {

    private var collectionViews = [UICollectionView]()

    // Animation properties
    private var animationStartTime = Date()
    private var animationDuration: TimeInterval = 600
    private var scrollLink: CADisplayLink?

    private var initialContentOffsets: [Int] = [10000, 500, 200, 20000, 700]
    private var targetContentOffsets: [Int] = [100, 15000, 25000, 5000, 10000]

    private let images: [String] = [
        "beastcast",
        "beasters",
        "bgame",
        "bigboss",
        "bluebombing",
        "bombcast",
        "bombin",
        "breakingbrad",
        "datinggames",
        "deadlysims",
        "demoderby",
        "e3",
        "exquisitecorps",
        "extralife",
        "farmer",
        "frights",
        "gaiden",
        "gametapes",
        "holiday",
        "jartime",
        "kingdomheartache",
        "mailbag",
        "marioparty",
        "massalex",
        "murderisland",
        "oldgames",
        "persona",
        "playdate",
        "punchout",
        "quicklooks",
        "rankingoffighters",
        "stealsunshine",
        "subbed",
        "unfinished",
        "upf",
        "vinnyvania",
        "vrodeo"
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        let overlay = UIView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.backgroundColor = UIColor(white: 0.2, alpha: 0.2)
        addSubview(overlay)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: -108),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 108),

            overlay.topAnchor.constraint(equalTo: topAnchor),
            overlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: bottomAnchor),
            overlay.leadingAnchor.constraint(equalTo: leadingAnchor)
        ])

        stack.alignment = .fill
        stack.axis = .vertical
        stack.distribution = .fillEqually

        for _ in 0..<5 {
            let view = makeCollectionView()
            stack.addArrangedSubview(view)
            collectionViews.append(view)
        }
    }

    func startAnimations() {
        animationStartTime = Date()
        scrollLink = CADisplayLink(target: self, selector: #selector(animateScrolls))
        scrollLink?.add(to: RunLoop.current, forMode: .common)

        for (view, offset) in zip(collectionViews, initialContentOffsets) {
            view.setContentOffset(CGPoint(x: offset, y: 0), animated: false)
        }
    }

    func stopAnimations() {
        scrollLink?.invalidate()
    }

    @objc private func animateScrolls() {
        let ratio = TimeInterval(abs(animationStartTime.timeIntervalSinceNow)) / animationDuration

        guard ratio < 1 else {
            // finish
            return
        }

        for (i, el) in collectionViews.enumerated() {
            let delta = ratio * Double(targetContentOffsets[i] - initialContentOffsets[i])
            let target = CGPoint(x: Double(initialContentOffsets[i]) + delta, y: 0.0)
            el.setContentOffset(target, animated: false)
        }
    }

    private func makeCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        let view = UICollectionView(frame: frame, collectionViewLayout: layout)
        view.dataSource = self
        view.delegate = self
        view.isUserInteractionEnabled = false
        view.register(ImageCell.self, forCellWithReuseIdentifier: "cell")
        return view
    }
}

extension ExcitingBackgroundView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1000
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? ImageCell else {
            fatalError()
        }
        cell.image = UIImage(named: "Show Images/\(images.randomElement()!)")
        return cell
    }
}

extension ExcitingBackgroundView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.height * 16.0 / 9.0, height: collectionView.frame.height)
    }
}

private class ImageCell: UICollectionViewCell {
    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }

    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 16.0),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16.0),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16.0),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16.0)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
