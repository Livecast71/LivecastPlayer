import Foundation

public struct LivecastState: Equatable {
    public var positionInfo: LivecastPositionInfo
    public var mediaInfo: LivecastMediaInfo
    public var playbackState: PlaybackState
    public var error: String?
}
