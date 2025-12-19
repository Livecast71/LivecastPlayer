import Foundation

protocol LivecastPlayerStatus: AnyObject {
    var currentItem: LivecastItem? { get }
    var playbackState: PlaybackState { get }
    var duration: TimeInterval { get }
    var currentPosition: TimeInterval { get }
    var bufferedPosition: TimeInterval { get }
    var playbackSpeed: Float { get }
    var error: Error? { get }
    var isSeeking: Bool { get }
}
