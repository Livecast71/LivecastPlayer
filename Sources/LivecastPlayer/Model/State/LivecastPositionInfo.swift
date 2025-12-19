import Foundation

public struct LivecastPositionInfo: Equatable {
    public var progress: Double {
        duration > 0.0 ? currentPosition / duration : 0.0
    }

    public var duration: TimeInterval = 0
    public var currentPosition: TimeInterval = 0
    public var bufferedPosition: TimeInterval = 0
}
