import BombAPI
import TVServices

class ContentProvider: TVTopShelfContentProvider {

    private let api = BombAPI()

    override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
        api.getRecentlyWatched(limit: 5)
            .done { videos in
                let section = self.makeContinueWatchingSection(with: videos)
                let content = TVTopShelfSectionedContent(sections: [section])
                completionHandler(content)
            }.catch { _ in
                completionHandler(nil)
            }
    }

    private func makeContinueWatchingSection(with videos: [BombVideo]) -> TVTopShelfItemCollection<TVTopShelfSectionedItem> {
        let section = TVTopShelfItemCollection(items: videos.map { $0.makeTopShelfItem() })
        section.title = "Continue watching"
        return section
    }
}

extension BombVideo {
    func makeTopShelfItem() -> TVTopShelfSectionedItem {
        let item = TVTopShelfSectionedItem(identifier: String(self.id))
        item.title = name
        item.imageShape = .hdtv
        item.setImageURL(images.super, for: .screenScale1x)
        return item
    }
}

