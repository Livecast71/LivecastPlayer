import Foundation
import AVFoundation

protocol LivecastPlayerEventListener: AnyObject {
    func onUpdatePlayerStatus(player: LivecastMediaPlayer)
    func onTimeUpdate(currentPosition: TimeInterval, bufferPosition: TimeInterval, player: LivecastMediaPlayer)
    func onDetectedMetadata(_ metadata: [KeySpaceMetadata])
}

protocol LivecastPlayable: LivecastPlayerStatus, LivecastControllable {
    func setListener(_ listener: LivecastPlayerEventListener?)
}

final class LivecastMediaPlayer: NSObject, LivecastPlayable {
    weak var listener: LivecastPlayerEventListener?

    private(set) var currentItem: LivecastItem?
    private(set) var playbackState: PlaybackState = .stopped
    private(set) var playbackSpeed: Float = 1.0
    private(set) var isSeeking: Bool = false
    private(set) var error: Error?

    private var lastKnownPosition: TimeInterval?
    private var startPosition: TimeInterval = 0

    let player: AVPlayer
    private let playerObserver: AVPlayerObserver
    private let itemObserver: AVPlayerItemObserver

    var duration: TimeInterval {
        guard let duration = player.currentItem?.duration else { return 0 }
        return max(0, CMTimeGetSeconds(duration))
    }

    var currentPosition: TimeInterval {
        guard let lastKnownPosition else {
            return currentItem != nil ? startPosition : 0
        }
        return lastKnownPosition
    }

    var bufferedPosition: TimeInterval {
        guard let range = player.currentItem?.loadedTimeRanges.first else { return 0 }
        let timeRange = range.timeRangeValue
        return CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration)
    }

    init(player: AVPlayer = AVPlayer(), notificationCenter: NotificationCenter = .default) {
        self.player = player
        self.playerObserver = AVPlayerObserver(notificationCenter: notificationCenter)
        self.itemObserver = AVPlayerItemObserver(notificationCenter: notificationCenter)
        super.init()
        playerObserver.delegate = self
        itemObserver.delegate = self
        playerObserver.startObserving(player: player)
    }

    func setListener(_ listener: LivecastPlayerEventListener?) {
        self.listener = listener
    }

    @MainActor
    func setStream(item: LivecastItem, playWhenReady: Bool, startPosition: TimeInterval) {
        currentItem = item
        self.startPosition = max(0, startPosition)
        itemObserver.stopObservingCurrentItem()

        let playerItem = AVPlayerItem(url: item.url)
        itemObserver.observe(item: playerItem)
        player.replaceCurrentItem(with: playerItem)

        seek(to: self.startPosition)
        if playWhenReady { play() }
    }

    @MainActor
    func clearStream() {
        itemObserver.stopObservingCurrentItem()
        player.replaceCurrentItem(with: nil)
        currentItem = nil
        lastKnownPosition = nil
        startPosition = 0
        playbackState = .stopped
    }

    @MainActor
    func play() {
        player.play()
        player.rate = playbackSpeed
    }

    @MainActor
    func pause() {
        player.pause()
    }

    @MainActor
    func stop() {
        clearStream()
    }

    @MainActor
    func seek(to position: TimeInterval) {
        guard currentItem != nil else { return }
        isSeeking = true
        startPosition = position
        let time = CMTime(seconds: max(0, position), preferredTimescale: 1000000)
        player.seek(to: time) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.isSeeking = false
                self.listener?.onUpdatePlayerStatus(player: self)
            }
        }
    }

    @MainActor
    func seekForward() {}

    @MainActor
    func seekBackward() {}

    @MainActor
    func setPlaybackSpeed(_ speed: Float) {
        playbackSpeed = speed
        if player.rate > 0 { player.rate = playbackSpeed }
    }

    @MainActor
    func invalidateCurrentItem(metadata: LivecastItemMetadata) {
        guard var item = currentItem else { return }
        item.metadata = metadata
        currentItem = item
    }

    private func didUpdateTime(desiredPosition: TimeInterval? = nil) {
        listener?.onTimeUpdate(
            currentPosition: desiredPosition ?? currentPosition,
            bufferPosition: bufferedPosition,
            player: self
        )
    }
}

extension LivecastMediaPlayer: AVPlayerObserverDelegate {
    func didUpdateCurrentPosition(time: TimeInterval) {
        guard !isSeeking, playbackState == .playing else { return }
        lastKnownPosition = time
        Task { @MainActor in
            didUpdateTime(desiredPosition: nil)
        }
    }

    func didReceiveInterruptionBegan() {
        Task { @MainActor in pause() }
    }

    func didReceiveInterruptionEndedAndShouldResume() {
        Task { @MainActor in play() }
    }

    func didUpdatePlayerStatus(status: AVPlayer.Status, timeControlStatus: AVPlayer.TimeControlStatus) {
        if player.currentItem == nil || currentItem == nil {
            playbackState = .stopped
            return
        }
        switch timeControlStatus {
        case .paused:
            playbackState = .paused
        case .waitingToPlayAtSpecifiedRate:
            playbackState = player.currentItem?.isPlaybackLikelyToKeepUp == true ? .playing : .buffering
        case .playing:
            playbackState = .playing
        @unknown default:
            break
        }
        Task { @MainActor in
            listener?.onUpdatePlayerStatus(player: self)
        }
    }
}

extension LivecastMediaPlayer: AVPlayerItemObserverDelegate {
    func didUpdatePlayerItem(item: AVPlayerItem?) {
        guard !isSeeking else { return }
        Task { @MainActor in didUpdateTime(desiredPosition: nil) }
    }

    func didPlayUntilEnd(item: AVPlayerItem?) {
        Task { @MainActor in pause() }
    }

    func didFailToPlayUntilEnd(item: AVPlayerItem?, error: Error?) {
        self.error = error
        Task { @MainActor in pause() }
    }

    func didDetectMetaData(groups: [AVTimedMetadataGroup]) {
        let metadata = groups.flatMap {
            $0.items
                .filter { $0.keySpace == .icy }
                .compactMap { IcyMetadata(avItem: $0) }
        }
        listener?.onDetectedMetadata(metadata.map { KeySpaceMetadata.icy($0) })
    }
}
