import Foundation
import AVFoundation
import AVFAudio

protocol AVPlayerObserverDelegate: AnyObject {
    func didUpdateCurrentPosition(time: TimeInterval)
    func didReceiveInterruptionBegan()
    func didReceiveInterruptionEndedAndShouldResume()
    func didUpdatePlayerStatus(status: AVPlayer.Status, timeControlStatus: AVPlayer.TimeControlStatus)
}

final class AVPlayerObserver: NSObject {
    weak var delegate: AVPlayerObserverDelegate?
    private weak var player: AVPlayer?
    private var timeObserver: Any?
    private let notificationCenter: NotificationCenter

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    deinit {
        stopObserving()
    }

    func startObserving(player: AVPlayer) {
        stopObserving()
        self.player = player
        beginNotificationsObserving()
        beginPeriodicTimeObserving()
        addKeyValuesObservables()
    }

    func stopObserving() {
        endNotificationsObserving()
        endPeriodicTimeObserving()
        removeKeyValueObservables()
        player = nil
    }
}

extension AVPlayerObserver {
    private func beginNotificationsObserving() {
        notificationCenter.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    private func endNotificationsObserving() {
        notificationCenter.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
    }

    @objc private func handleInterruption(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        switch type {
        case .began:
            Task { @MainActor in delegate?.didReceiveInterruptionBegan() }
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                Task { @MainActor in delegate?.didReceiveInterruptionEndedAndShouldResume() }
            }
        @unknown default:
            break
        }
    }
}

extension AVPlayerObserver {
    private func addKeyValuesObservables() {
        player?.addObserver(self, forKeyPath: "currentItem", options: [.old, .new], context: nil)
        player?.addObserver(self, forKeyPath: "status", options: [.old, .new], context: nil)
        player?.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        didUpdatePlayerState()
    }

    private func removeKeyValueObservables() {
        player?.removeObserver(self, forKeyPath: "currentItem")
        player?.removeObserver(self, forKeyPath: "status")
        player?.removeObserver(self, forKeyPath: "timeControlStatus")
    }

    private func didUpdatePlayerState() {
        guard let player else { return }
        Task { @MainActor in
            delegate?.didUpdatePlayerStatus(status: player.status, timeControlStatus: player.timeControlStatus)
        }
    }
}

extension AVPlayerObserver {
    private func beginPeriodicTimeObserving() {
        guard let player else { return }
        endPeriodicTimeObserving()
        let interval = CMTimeMakeWithSeconds(1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: nil) { time in
            Task { @MainActor in
                self.delegate?.didUpdateCurrentPosition(time: CMTimeGetSeconds(time))
            }
        }
    }

    private func endPeriodicTimeObserving() {
        guard let player, let timeObserver else { return }
        player.removeTimeObserver(timeObserver)
        self.timeObserver = nil
    }
}
