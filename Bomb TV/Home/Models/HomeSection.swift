import BombAPI
import Foundation

protocol CellInformationProviding {
    var previewImage: URL { get }
    var title: String { get }
}

enum HighlightItem: Hashable, Equatable, CellInformationProviding {
    case latest(VideoViewModel)
    case liveStream(LiveVideo)
    case resumeWatching(VideoViewModel)

    var progress: Float? {
        switch self {
        case .latest(let video): return video.progress
        case .liveStream: return nil
        case .resumeWatching(let video): return video.progress
        }
    }

    var previewImage: URL {
        switch self {
        case .latest(let viewModel):
            return viewModel.video.images.super
        case .liveStream(let video):
            return video.image
        case .resumeWatching(let viewModel):
            return viewModel.video.images.super
        }
    }

    var prompt: String {
        switch self {
        case .latest(let viewModel):
            return "Recently added: \(viewModel.video.name)"
        case .liveStream(let video):
            return "Live now: \(video.title)"
        case .resumeWatching(let viewModel):
            return "Continue watching \(viewModel.video.name)"
        }
    }

    var title: String {
        switch self {
        case .latest(let viewModel):
            return viewModel.video.name
        case .liveStream(let video):
            return video.title
        case .resumeWatching(let viewModel):
            return viewModel.video.name
        }
    }

    var video: VideoViewModel? {
        switch self {
        case .latest(let viewModel):
            return viewModel
        case .liveStream:
            return nil
        case .resumeWatching(let viewModel):
            return viewModel
        }
    }
}

enum HomeScreenItem: Hashable, CellInformationProviding {
    case highlight(HighlightItem)
    case show(Show)
    case video(VideoViewModel)

    var previewImage: URL {
        switch self {
        case .highlight(let highlightItem):
            return highlightItem.previewImage
        case .show(let show):
            return show.images.super
        case .video(let viewModel):
            return viewModel.video.images.medium
        }
    }

    var progress: Float? {
        switch self {
        case .highlight(let highlight): return highlight.progress
        case .video(let viewModel): return viewModel.progress
        default: return nil
        }
    }

    var title: String {
        switch self {
        case .highlight(let highlightItem):
            return highlightItem.title
        case .show(let show):
            return show.title
        case .video(let viewModel):
            return viewModel.video.name
        }
    }

    var video: VideoViewModel? {
        switch self {
        case .highlight(let highlightItem):
            return highlightItem.video
        case .show:
            return nil
        case .video(let video):
            return video
        }
    }
}

enum HomeSection: Hashable, Equatable {

    case highlight([HighlightItem])
    case shows([Show])
    case videoRow(String, [VideoViewModel])
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
        case .videoRow(let title, _):
            hasher.combine(title)
        case .shows:
            hasher.combine(2)
            hasher.combine(title)
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
