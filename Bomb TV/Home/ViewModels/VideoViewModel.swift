import BombAPI
import Foundation
import PromiseKit

struct VideoViewModel {
    let resumePoint: TimeInterval?
    let video: BombVideo

    var isCompleted: Bool {
        guard let resumePoint = resumePoint else { return false }
        return resumePoint > video.duration - 10
    }

    var isResumable: Bool {
        guard let resumePoint = resumePoint else { return false }
        return resumePoint > 0 && resumePoint < video.duration - 10
    }

    var progress: Float? {
        guard isResumable, let resumePoint = resumePoint else { return nil }
        return Float(resumePoint) / Float(video.duration)
    }
}

extension VideoViewModel: Equatable, Hashable {}

extension Thenable where T == [BombVideo] {
    func mapResumeTimes(on: DispatchQueue? = conf.Q.map,
                        flags: DispatchWorkItemFlags? = nil,
                        api: ResumeTimeProvider) -> Promise<[VideoViewModel]> {
        return map(on: on, flags: flags) { $0.map { video -> VideoViewModel in
            let resumePoint = api.resumePoint(for: video)
            return VideoViewModel(resumePoint: resumePoint, video: video)
        } }
    }
}
