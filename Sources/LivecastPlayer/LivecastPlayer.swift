import Foundation
#if canImport(UIKit)
import Combine
#endif

public class LivecastPlayer {
    public let controller: LivecastController
    public let state: LivecastStateReader

    private let audioSessionService: AudioSessionService
    private let remoteService: RemoteService
    private let stateObserver: LivecastStateObserver

    public convenience init(
        audioSessionConfig: AudioSessionConfig = AudioSessionConfig(),
        seekConfig: SeekConfig = SeekConfig(),
        imageConfig: ImageConfig = ImageConfig()
    ) {
        let mediaPlayer = LivecastMediaPlayer()
        let state = LivecastStateProvider()
        let controller = LivecastController(
            player: mediaPlayer,
            state: state,
            seekConfig: seekConfig
        )
        let observer = LivecastStateObserver(player: mediaPlayer, stateProvider: state)
        self.init(
            controller: controller,
            state: state,
            stateObserver: observer,
            audioSessionConfig: audioSessionConfig,
            seekConfig: seekConfig,
            imageConfig: imageConfig
        )
    }

    init(
        controller: LivecastController,
        state: LivecastStateWriter,
        stateObserver: LivecastStateObserver,
        audioSessionConfig: AudioSessionConfig,
        seekConfig: SeekConfig,
        imageConfig: ImageConfig
    ) {
        self.controller = controller
        self.state = state
        self.stateObserver = stateObserver

        self.audioSessionService = AudioSessionService(
            session: .sharedInstance(),
            state: state,
            config: audioSessionConfig
        )
        self.remoteService = RemoteService(
            controller: controller,
            state: state,
            seekConfig: seekConfig,
            imageConfig: imageConfig
        )
        enableRemoteService()
    }

    public func updateAudioSession(config: AudioSessionConfig) throws {
        try audioSessionService.update(config: config)
    }

    public func enableRemoteService() {
        remoteService.enable()
    }

    public func disableRemoteService() {
        remoteService.disable()
    }
}

#if canImport(UIKit)
import Combine
import UIKit

public extension LivecastPlayer {
    func makePopupViewController() -> UIViewController {
        LivecastPopupViewController(player: self)
    }

    func makeEmbeddablePopupViewController(onDismiss: @escaping (Bool) -> Void) -> UIViewController {
        LivecastPopupViewController(player: self, onDismiss: onDismiss)
    }

    func showMiniBar(in hostViewController: UIViewController, onTap: @escaping () -> Void) {
        hideMiniBar()
        guard state.current.mediaInfo.currentItem != nil else { return }
        let title = state.current.mediaInfo.currentItem?.metadata.title ?? ""
        let bar = LivecastMiniPlayerBarView()
        bar.configure(title: title)
        bar.onTap = onTap
        hostViewController.view.addSubview(bar)
        bar.translatesAutoresizingMaskIntoConstraints = false
        let leading = bar.leadingAnchor.constraint(equalTo: hostViewController.view.leadingAnchor, constant: 16)
        let trailing = bar.trailingAnchor.constraint(equalTo: hostViewController.view.trailingAnchor, constant: -16)
        let bottom: NSLayoutConstraint
        if let tabBar = hostViewController as? UITabBarController {
            bottom = bar.bottomAnchor.constraint(equalTo: tabBar.tabBar.topAnchor, constant: -12)
        } else {
            bottom = bar.bottomAnchor.constraint(equalTo: hostViewController.view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        }
        NSLayoutConstraint.activate([leading, trailing, bottom])
        miniBarView = bar
        miniBarHost = hostViewController
        miniBarCancellable = state.currentPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                if state.mediaInfo.currentItem == nil {
                    self?.hideMiniBar()
                }
            }
    }

    func hideMiniBar() {
        miniBarView?.removeFromSuperview()
        miniBarView = nil
        miniBarHost = nil
        miniBarCancellable?.cancel()
        miniBarCancellable = nil
    }
}

private extension LivecastPlayer {
    static var miniBarViewKey: UInt8 = 0
    static var miniBarHostKey: UInt8 = 0
    static var miniBarCancellableKey: UInt8 = 0

    var miniBarView: LivecastMiniPlayerBarView? {
        get { objc_getAssociatedObject(self, &Self.miniBarViewKey) as? LivecastMiniPlayerBarView }
        set { objc_setAssociatedObject(self, &Self.miniBarViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var miniBarHost: UIViewController? {
        get { objc_getAssociatedObject(self, &Self.miniBarHostKey) as? UIViewController }
        set { objc_setAssociatedObject(self, &Self.miniBarHostKey, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }

    var miniBarCancellable: AnyCancellable? {
        get { objc_getAssociatedObject(self, &Self.miniBarCancellableKey) as? AnyCancellable }
        set { objc_setAssociatedObject(self, &Self.miniBarCancellableKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}
#endif

