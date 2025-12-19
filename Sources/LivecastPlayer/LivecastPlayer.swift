import Foundation

public class LivecastPlayer {
    public let controller: LivecastController
    public let state: LivecastStateReader

    private let audioSessionService: AudioSessionService
    private let remoteService: RemoteService

    public convenience init(
        mediaPlayer: LivecastMediaPlayer = LivecastMediaPlayer(),
        audioSessionConfig: AudioSessionConfig = AudioSessionConfig(),
        seekConfig: SeekConfig = SeekConfig(),
        imageConfig: ImageConfig = ImageConfig()
    ) {
        let state = LivecastStateProvider()
        let controller = LivecastController(
            player: mediaPlayer,
            state: state,
            seekConfig: seekConfig
        )
        _ = LivecastStateObserver(player: mediaPlayer, stateProvider: state)
        self.init(
            controller: controller,
            state: state,
            audioSessionConfig: audioSessionConfig,
            seekConfig: seekConfig,
            imageConfig: imageConfig
        )
    }

    init(
        controller: LivecastController,
        state: LivecastStateWriter,
        audioSessionConfig: AudioSessionConfig,
        seekConfig: SeekConfig,
        imageConfig: ImageConfig
    ) {
        self.controller = controller
        self.state = state

        self.audioSessionService = AudioSessionService(
            session: .sharedInstance(),
            state: state,
            config: audioSessionConfig
        )
        self.remoteService = RemoteService(
            controller: controller,
            state: state,
            seekConfig: seekConfig,
            imageConfig: imageConfig
        )
        enableRemoteService()
    }

    public func updateAudioSession(config: AudioSessionConfig) throws {
        try audioSessionService.update(config: config)
    }

    public func enableRemoteService() {
        remoteService.enable()
    }

    public func disableRemoteService() {
        remoteService.disable()
    }
}
