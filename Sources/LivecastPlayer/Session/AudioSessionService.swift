import Combine
import AVKit

final class AudioSessionService {
    private let session: AVAudioSession
    private let state: LivecastStateReader
    private var config: AudioSessionConfig
    private var cancellable: AnyCancellable?

    init(session: AVAudioSession, state: LivecastStateReader, config: AudioSessionConfig) {
        self.session = session
        self.state = state
        self.config = config
        cancellable = state.currentPublisher
            .map(\.playbackState.isPlayingOrBuffering)
            .removeDuplicates()
            .filter { $0 }
            .sink { [weak self] _ in try? self?.updateSession() }
    }

    private func updateSession() throws {
        guard config.activationMode == .onPlayback,
              state.current.playbackState.isPlayingOrBuffering else { return }
        try session.setCategory(config.sessionCategory, mode: config.sessionMode, policy: config.sessionPolicy, options: config.sessionOptions)
        try session.setActive(true)
    }

    func update(config: AudioSessionConfig) throws {
        self.config = config
        try updateSession()
    }
}
