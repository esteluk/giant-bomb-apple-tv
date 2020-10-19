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

extension BombVideo {
    func viewModel(api: ResumeTimeProvider & ShowProvider) -> VideoViewModel {
        let resumePoint = api.resumePoint(for: self)
        return VideoViewModel(resumePoint: resumePoint, video: self)
    }
}
