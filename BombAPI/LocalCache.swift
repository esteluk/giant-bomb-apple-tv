import Foundation
import os.log

class LocalCache: CachedData, CachedResumePointData {
    private var data = [Int: BombVideo]()
    private var savedTimeData = [Int: TimeInterval]()

    static let shared = LocalCache()

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

    func resumePoint(for video: BombVideo) -> TimeInterval? {
        guard let time = savedTimeData[video.id] else {
            return video.resumePoint
        }
        return time
    }

    func updateResumePoint(point: SavedVideoProgress) {
        savedTimeData[point.videoId] = point.savedTime
    }

    func updateResumePoint(_ resumePoint: TimeInterval, for video: BombVideo) {
        savedTimeData[video.id] = resumePoint
    }
}

protocol CachedData {
    func requestVideo(for id: Int) -> BombVideo?
    func storeVideo(_ video: BombVideo)
}

protocol CachedResumePointData {
    func resumePoint(for video: BombVideo) -> TimeInterval?
    func updateResumePoint(point: SavedVideoProgress)
    func updateResumePoint(_ resumePoint: TimeInterval, for video: BombVideo)
}
