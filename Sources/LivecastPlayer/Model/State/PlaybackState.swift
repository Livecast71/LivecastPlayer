import Foundation

public enum PlaybackState {
    case playing
    case buffering
    case paused
    case stopped

    public var isPlayingOrBuffering: Bool {
        self == .buffering || self == .playing
    }
}
