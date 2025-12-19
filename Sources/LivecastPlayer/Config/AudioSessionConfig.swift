import AVKit

public struct AudioSessionConfig {
    public enum ActivationMode {
        case ignored
        case onPlayback
    }

    public let activationMode: ActivationMode
    public let sessionCategory: AVAudioSession.Category
    public let sessionMode: AVAudioSession.Mode
    public let sessionPolicy: AVAudioSession.RouteSharingPolicy
    public let sessionOptions: AVAudioSession.CategoryOptions

    public init(
        activationMode: ActivationMode = .onPlayback,
        sessionCategory: AVAudioSession.Category = .playback,
        sessionMode: AVAudioSession.Mode = .default,
        sessionPolicy: AVAudioSession.RouteSharingPolicy = .longFormAudio,
        sessionOptions: AVAudioSession.CategoryOptions = []
    ) {
        self.activationMode = activationMode
        self.sessionCategory = sessionCategory
        self.sessionMode = sessionMode
        self.sessionPolicy = sessionPolicy
        self.sessionOptions = sessionOptions
    }
}
