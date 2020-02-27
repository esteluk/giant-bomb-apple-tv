import BombAPI
import Foundation

enum Section: Hashable, Equatable {

    case highlight
    case latest([BombVideo])
    case shows([Show])
    case inProgress

    var title: String {
        switch self {
        case .highlight:
            return "Highlights"
        case .latest:
            return "Latest"
        case .shows:
            return "Shows"
        case .inProgress:
            return "Continue watching"
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .latest(let videos):
            hasher.combine(videos)
        case .shows(let shows):
            hasher.combine(shows)
        case .highlight:
            hasher.combine(3)
        case .inProgress:
            hasher.combine(4)
        }
    }

    static func == (lhs: Section, rhs: Section) -> Bool {
        switch (lhs, rhs) {
        case (.highlight, .highlight): return true
        case (.inProgress, .inProgress): return true
        case (.latest(let a), .latest(let b)): return a == b
        case (.shows(let a), .shows(let b)): return a == b
        default:
            return false
        }
    }

}
