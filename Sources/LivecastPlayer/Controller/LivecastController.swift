import Foundation

public class LivecastController: LivecastControllable {
    private let player: LivecastMediaPlayer
    private let state: LivecastStateWriter
    private let seekConfig: SeekConfig

    init(player: LivecastMediaPlayer, state: LivecastStateWriter, seekConfig: SeekConfig) {
        self.player = player
        self.state = state
        self.seekConfig = seekConfig
    }

    @MainActor
    public func setStream(item: LivecastItem, playWhenReady: Bool, startPosition: TimeInterval) {
        player.setStream(item: item, playWhenReady: playWhenReady, startPosition: startPosition)
    }

    @MainActor
    public func clearStream() {
        player.clearStream()
    }

    @MainActor
    public func play() {
        player.play()
    }

    @MainActor
    public func pause() {
        player.pause()
    }

    @MainActor
    public func stop() {
        player.stop()
    }

    @MainActor
    public func seek(to position: TimeInterval) {
        player.seek(to: position)
    }

    @MainActor
    public func seekForward() {
        let currentPosition = state.current.positionInfo.currentPosition
        player.seek(to: currentPosition + seekConfig.seekForwardStep)
    }

    @MainActor
    public func seekBackward() {
        let currentPosition = state.current.positionInfo.currentPosition
        player.seek(to: currentPosition - seekConfig.seekBackStep)
    }

    @MainActor
    public func setPlaybackSpeed(_ speed: Float) {
        player.setPlaybackSpeed(speed)
    }

    @MainActor
    public func invalidateCurrentItem(metadata: LivecastItemMetadata) {
        player.invalidateCurrentItem(metadata: metadata)
    }
}
