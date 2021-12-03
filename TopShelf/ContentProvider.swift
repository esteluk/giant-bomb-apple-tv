import BombAPI
import TVServices

class ContentProvider: TVTopShelfContentProvider {

    private let api = BombAPI()

    override func loadTopShelfContent() async -> TVTopShelfContent? {
        guard let token = AuthenticationStore().registrationToken else {
            return nil
        }

        BombAPI.setAPIKey(token)
        do {
            let recentlyWatched = try await api.getRecentlyWatched()
            let section = makeContinueWatchingSection(with: recentlyWatched)
            return TVTopShelfSectionedContent(sections: [section])
        } catch {
            return nil
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
        if let resumePoint = resumePoint {
            item.playbackProgress = resumePoint / duration
        }
        item.displayAction = TVTopShelfAction(url: launchUrl)
        item.playAction = TVTopShelfAction(url: launchUrl)
        item.setImageURL(images.super, for: .screenScale1x)
        return item
    }
}

