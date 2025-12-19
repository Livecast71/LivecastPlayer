import Foundation

final class LivecastStateObserver {
    private let player: LivecastMediaPlayer
    private let stateProvider: LivecastStateWriter

    init(player: LivecastMediaPlayer, stateProvider: LivecastStateWriter) {
        self.player = player
        self.stateProvider = stateProvider
        player.setListener(self)
    }
}

extension LivecastStateObserver: LivecastPlayerEventListener {
    func onUpdatePlayerStatus(player: LivecastMediaPlayer) {
        updateState()
    }

    func onTimeUpdate(currentPosition: TimeInterval, bufferPosition: TimeInterval, player: LivecastMediaPlayer) {
        var state = stateProvider.current
        state.positionInfo.currentPosition = currentPosition
        state.positionInfo.bufferedPosition = bufferPosition
        state.positionInfo.duration = player.duration
        stateProvider.setState(state)
    }

    func onDetectedMetadata(_ metadata: [KeySpaceMetadata]) {
        var state = stateProvider.current
        state.mediaInfo.detectedMetadata = metadata
        stateProvider.setState(state)
    }

    private func updateState() {
        var state = stateProvider.current
        state.mediaInfo.currentItem = player.currentItem
        state.positionInfo.duration = player.duration
        state.positionInfo.currentPosition = player.currentPosition
        state.positionInfo.bufferedPosition = player.bufferedPosition
        state.playbackState = player.playbackState
        state.error = player.error?.localizedDescription
        stateProvider.setState(state)
    }
}
