import AVKit
import BombAPI

extension VideoUrls {
    func url(for quality: SettingsBundleHelper.VideoQualityOptions) -> URL? {
        switch quality {
        case .low: return lowQuality
        case .high: return mediumQuality
        case .hd: return highQuality
        }
    }
}

extension BombVideo {
    static let presentationInterval: TimeInterval = 15.0

    func makeContentProposal(from prosposingVideo: BombVideo) -> AVContentProposal {
        let time = CMTime(value: CMTimeValue(prosposingVideo.duration - BombVideo.presentationInterval), timescale: 1)

        let proposal = AVContentProposal(contentTimeForTransition: time, title: self.name, previewImage: nil)
        proposal.metadata = externalMetadata
        let quality = SettingsBundleHelper().selectedVideoQuality
        proposal.url = videoUrls.url(for: quality)
        return proposal
    }
}
