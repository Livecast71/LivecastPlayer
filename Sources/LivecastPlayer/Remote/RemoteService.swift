#if canImport(UIKit)
import UIKit
import Combine
import MediaPlayer

final class RemoteService {
    private let controller: LivecastController
    private let state: LivecastStateReader
    private let seekConfig: SeekConfig
    private let imageConfig: ImageConfig
    private var cancellables = Set<AnyCancellable>()

    init(controller: LivecastController, state: LivecastStateReader, seekConfig: SeekConfig, imageConfig: ImageConfig) {
        self.controller = controller
        self.state = state
        self.seekConfig = seekConfig
        self.imageConfig = imageConfig
    }

    func enable() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        state.currentPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateNowPlaying(state: state)
            }
            .store(in: &cancellables)
    }

    func disable() {
        UIApplication.shared.endReceivingRemoteControlEvents()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        cancellables = []
    }

    private func updateNowPlaying(state: LivecastState) {
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = state.mediaInfo.currentItem?.metadata.title
        info[MPMediaItemPropertyArtist] = state.mediaInfo.currentItem?.metadata.artist
        info[MPNowPlayingInfoPropertyIsLiveStream] = true
        info[MPMediaItemPropertyPlaybackDuration] = state.positionInfo.duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = state.positionInfo.currentPosition
        info[MPNowPlayingInfoPropertyPlaybackRate] = state.playbackState == .playing ? 1.0 : 0
        #if canImport(UIKit)
        if let placeholder = imageConfig.artworkPlaceholder {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: placeholder.size) { _ in placeholder }
        }
        #endif
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
#endif
