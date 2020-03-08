import BombAPI
import Foundation

protocol CellInformationProviding {
    var previewImage: URL { get }
    var title: String { get }
}

enum HighlightItem: Hashable, Equatable, CellInformationProviding {
    case liveStream(LiveVideo)
    case resumeWatching(BombVideo)

    var previewImage: URL {
        switch self {
        case .liveStream(let video):
            return video.image
        case .resumeWatching(let video):
            return video.images.super
        }
    }

    var prompt: String {
        switch self {
        case .liveStream(let video):
            return "Live now: \(video.title)"
        case .resumeWatching(let video):
            return "Continue watching \(video.name)"
        }
    }

    var title: String {
        switch self {
        case .liveStream(let video):
            return video.title
        case .resumeWatching(let video):
            return video.name
        }
    }
}

enum HomeScreenItem: Hashable, CellInformationProviding {
    case highlight(HighlightItem)
    case show(Show)
    case video(BombVideo)

    var previewImage: URL {
        switch self {
        case .highlight(let highlightItem):
            return highlightItem.previewImage
        case .show(let show):
            return show.images.super
        case .video(let video):
            return video.images.medium
        }
    }

    var title: String {
        switch self {
        case .highlight(let highlightItem):
            return highlightItem.title
        case .show(let show):
            return show.title
        case .video(let video):
            return video.name
        }
    }
}

enum HomeSection: Hashable, Equatable {

    case highlight([HighlightItem])
    case shows([Show])
    case videoRow(String, [BombVideo])
    case inProgress

    var title: String {
        switch self {
        case .highlight:
            return "Highlights"
        case .videoRow(let title, _):
            return title
        case .shows:
            return "Shows"
        case .inProgress:
            return "Continue watching"
        }
    }

    var hasHeader: Bool {
        switch self {
        case .highlight: return false
        default: return true
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .videoRow(let title, let videos):
            hasher.combine(title)
            hasher.combine(videos)
        case .shows(let shows):
            hasher.combine(shows)
        case .highlight:
            hasher.combine(3)
        case .inProgress:
            hasher.combine(4)
        }
    }

    static func == (lhs: HomeSection, rhs: HomeSection) -> Bool {
        switch (lhs, rhs) {
        case (.highlight, .highlight): return true
        case (.inProgress, .inProgress): return true
        case (.videoRow(let aT, let aV), .videoRow(let bT, let bV)): return aT == bT && aV == bV
        case (.shows(let a), .shows(let b)): return a == b
        default:
            return false
        }
    }

}
