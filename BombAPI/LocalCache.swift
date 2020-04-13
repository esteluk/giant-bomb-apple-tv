import os.log

class LocalCache {
    private var data = [Int: BombVideo]()

    func requestVideo(for id: Int) -> BombVideo? {
        guard let video = data[id] else {
            return nil
        }
        print("Retrieved video \(video.name) from cache")
        return video
    }

    func storeVideo(_ video: BombVideo) {
        let id = video.id
        data[id] = video
    }
}
