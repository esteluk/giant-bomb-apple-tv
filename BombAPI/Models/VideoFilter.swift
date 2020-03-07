import Foundation

public enum VideoFilter {
    case date(start: Date, end: Date)
    case keyShow(KeyShow)
    case premium
    case show(Show)

    var queryItem: URLQueryItem {
        switch self {
        case .date(let start, let end):
            let f = DateFormatter.filterDateFormatter
            return URLQueryItem(name: "filter", value: "publish_date:\(f.string(from: start))|\(f.string(from: end))")
        case .keyShow(let show):
            return URLQueryItem(name: "filter", value: "video_show:\(show.rawValue)")
        case .premium:
            return URLQueryItem(name: "filter", value: "premium:true")
        case .show(let show):
            return URLQueryItem(name: "filter", value: "video_show:\(show.id)")
        }
    }
}
