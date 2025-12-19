import Foundation

public struct SeekConfig {
    public let seekBackStep: TimeInterval
    public let seekForwardStep: TimeInterval

    public init(seekBackStep: TimeInterval = 10, seekForwardStep: TimeInterval = 30) {
        self.seekBackStep = seekBackStep
        self.seekForwardStep = seekForwardStep
    }
}
