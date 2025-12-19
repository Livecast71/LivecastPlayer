import Foundation
import AVFoundation

protocol AVPlayerItemObserverDelegate: AnyObject {
    func didUpdatePlayerItem(item: AVPlayerItem?)
    func didPlayUntilEnd(item: AVPlayerItem?)
    func didFailToPlayUntilEnd(item: AVPlayerItem?, error: Error?)
    func didDetectMetaData(groups: [AVTimedMetadataGroup])
}

final class AVPlayerItemObserver: NSObject {
    weak var delegate: AVPlayerItemObserverDelegate?
    private var currentItem: AVPlayerItem?
    private var keyValueObservations: [NSKeyValueObservation] = []
    private var metadataOutput: AVPlayerItemMetadataOutput?
    private let notificationCenter: NotificationCenter

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    deinit {
        stopObservingCurrentItem()
    }

    func observe(item: AVPlayerItem) {
        stopObservingCurrentItem()
        currentItem = item
        beginObservingMetadata()
        beginNotificationsObserving()
        addKeyValuesObservables()
    }

    func stopObservingCurrentItem() {
        stopObservingMetadata()
        endNotificationsObserving()
        removeKeyValueObservables()
        currentItem = nil
    }
}

extension AVPlayerItemObserver {
    private func beginNotificationsObserving() {
        guard let item = currentItem else { return }
        notificationCenter.addObserver(
            self,
            selector: #selector(didPlayUntilEnd),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: item
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(didFailToPlayUntilEnd),
            name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime,
            object: item
        )
    }

    private func endNotificationsObserving() {
        guard let item = currentItem else { return }
        notificationCenter.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
        notificationCenter.removeObserver(self, name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: item)
    }

    @objc private func didPlayUntilEnd() {
        Task { @MainActor in delegate?.didPlayUntilEnd(item: currentItem) }
    }

    @objc private func didFailToPlayUntilEnd(notification: NSNotification) {
        let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
        Task { @MainActor in delegate?.didFailToPlayUntilEnd(item: currentItem, error: error) }
    }
}

extension AVPlayerItemObserver {
    private func addKeyValuesObservables() {
        if let item = currentItem {
            let duration = item.observe(\.duration, options: [.old, .new]) { [weak self] _, _ in
                self?.didUpdatePlayerItem()
            }
            let loadedTimeRanges = item.observe(\.loadedTimeRanges, options: [.old, .new]) { [weak self] _, _ in
                self?.didUpdatePlayerItem()
            }
            keyValueObservations = [duration, loadedTimeRanges]
        }
    }

    private func removeKeyValueObservables() {
        keyValueObservations = []
    }

    private func didUpdatePlayerItem() {
        Task { @MainActor in delegate?.didUpdatePlayerItem(item: currentItem) }
    }
}

extension AVPlayerItemObserver: AVPlayerItemMetadataOutputPushDelegate {
    private func beginObservingMetadata() {
        stopObservingMetadata()
        guard let item = currentItem else { return }
        let output = AVPlayerItemMetadataOutput()
        output.setDelegate(self, queue: .main)
        item.add(output)
        metadataOutput = output
    }

    private func stopObservingMetadata() {
        guard let output = metadataOutput, let item = currentItem else {
            metadataOutput = nil
            return
        }
        item.remove(output)
        metadataOutput = nil
    }

    func metadataOutput(_ output: AVPlayerItemMetadataOutput, didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup], from track: AVPlayerItemTrack?) {
        Task { @MainActor in delegate?.didDetectMetaData(groups: groups) }
    }
}
