import Foundation

protocol LivecastControllable: AnyObject {
    @MainActor
    func setStream(item: LivecastItem, playWhenReady: Bool, startPosition: TimeInterval)

    @MainActor
    func clearStream()

    @MainActor
    func play()

    @MainActor
    func pause()

    @MainActor
    func stop()

    @MainActor
    func seek(to position: TimeInterval)

    @MainActor
    func seekForward()

    @MainActor
    func seekBackward()

    @MainActor
    func setPlaybackSpeed(_ speed: Float)

    @MainActor
    func invalidateCurrentItem(metadata: LivecastItemMetadata)
}
