#if canImport(UIKit)
import UIKit
import Combine

private final class LivecastPopupBackgroundView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        // Let touches pass through the empty background; only intercept inside subviews.
        return view === self ? nil : view
    }
}

public final class LivecastPopupViewController: UIViewController {
    private let player: LivecastPlayer
    private let onDismiss: ((Bool) -> Void)?
    private let containerView = UIView()
    private let closeButton = UIButton(type: .system)
    private let playPauseButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    private let backwardButton = UIButton(type: .system)
    private let forwardButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let elapsedLabel = UILabel()
    private let remainingLabel = UILabel()
    private var cancellables = Set<AnyCancellable>()
    private var didAutoDismiss = false
    private var hasStopped = false

    public init(player: LivecastPlayer, onDismiss: ((Bool) -> Void)? = nil) {
        self.player = player
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = LivecastPopupBackgroundView()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupButtons()
        observeState()
    }

    private func setupButtons() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        backwardButton.translatesAutoresizingMaskIntoConstraints = false
        forwardButton.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        elapsedLabel.translatesAutoresizingMaskIntoConstraints = false
        remainingLabel.translatesAutoresizingMaskIntoConstraints = false

        backwardButton.setImage(UIImage(systemName: "gobackward.15"), for: .normal)
        backwardButton.tintColor = .label
        backwardButton.addTarget(self, action: #selector(backwardTapped), for: .touchUpInside)

        playPauseButton.tintColor = .label
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)

        stopButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
        stopButton.tintColor = .label
        stopButton.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)

        forwardButton.setImage(UIImage(systemName: "goforward.15"), for: .normal)
        forwardButton.tintColor = .label
        forwardButton.addTarget(self, action: #selector(forwardTapped), for: .touchUpInside)

        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2

        elapsedLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        remainingLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        elapsedLabel.textColor = .secondaryLabel
        remainingLabel.textColor = .secondaryLabel
        elapsedLabel.text = "0:00"
        remainingLabel.text = "-0:00"

        progressView.progressTintColor = .systemBlue
        progressView.trackTintColor = .secondarySystemBackground
        progressView.transform = CGAffineTransform(scaleX: 1, y: 2)

        let closeConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: closeConfig), for: .normal)
        closeButton.tintColor = .secondaryLabel
        closeButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.masksToBounds = false
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.2
        containerView.layer.shadowRadius = 12
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)

        let buttonsStack = UIStackView(arrangedSubviews: [backwardButton, playPauseButton, stopButton, forwardButton])
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 32
        buttonsStack.alignment = .center
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false

        let timeLabelsStack = UIStackView(arrangedSubviews: [elapsedLabel, UIView(), remainingLabel])
        timeLabelsStack.axis = .horizontal
        timeLabelsStack.alignment = .fill
        timeLabelsStack.translatesAutoresizingMaskIntoConstraints = false

        let verticalStack = UIStackView(arrangedSubviews: [titleLabel, progressView, timeLabelsStack])
        verticalStack.axis = .vertical
        verticalStack.spacing = 8
        verticalStack.alignment = .fill
        verticalStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(containerView)
        containerView.addSubview(verticalStack)
        containerView.addSubview(buttonsStack)
        containerView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),

            verticalStack.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 8),
            verticalStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            verticalStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),

            buttonsStack.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            buttonsStack.topAnchor.constraint(equalTo: verticalStack.bottomAnchor, constant: 16),
            buttonsStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }

    private func observeState() {
        player.state.currentPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateProgress(with: state)
            }
            .store(in: &cancellables)
    }

    @objc
    private func playPauseTapped() {
        Task { @MainActor in
            if player.state.current.playbackState.isPlayingOrBuffering {
                player.controller.pause()
            } else {
                player.controller.play()
            }
        }
    }

    @objc
    private func stopTapped() {
        hasStopped = true
        Task { @MainActor in
            player.controller.stop()
        }
    }

    @objc
    private func backwardTapped() {
        Task { @MainActor in
            let current = self.player.state.current.positionInfo.currentPosition
            self.player.controller.seek(to: max(current - 15, 0))
        }
    }

    @objc
    private func forwardTapped() {
        Task { @MainActor in
            let current = self.player.state.current.positionInfo.currentPosition
            self.player.controller.seek(to: current + 15)
        }
    }

    @objc
    private func closeTapped() {
        let shouldShowMiniBar = !hasStopped
            && player.state.current.mediaInfo.currentItem != nil
            && player.state.current.playbackState != .stopped
        if let onDismiss {
            onDismiss(shouldShowMiniBar)
        } else {
            dismiss(animated: true)
        }
    }

    private func dismissPopup(shouldShowMiniBar: Bool = false) {
        if let onDismiss {
            onDismiss(shouldShowMiniBar)
        } else {
            dismiss(animated: true)
        }
    }

    private func updateProgress(with state: LivecastState) {
        let position = state.positionInfo.currentPosition
        let duration = state.positionInfo.duration
        let title = state.mediaInfo.currentItem?.metadata.title ?? ""
        let isPlaying = state.playbackState.isPlayingOrBuffering
        playPauseButton.setImage(UIImage(systemName: isPlaying ? "pause.fill" : "play.fill"), for: .normal)

        if duration > 0 {
            let progress = position / duration
            progressView.progress = Float(max(0, min(progress, 1)))
        } else if position > 0 {
            // Fallback: show some progress even if duration is unknown
            // Treat first 60 seconds as full range for local files.
            let progress = min(position / 60.0, 1.0)
            progressView.progress = Float(progress)
        } else {
            progressView.progress = 0
        }

        titleLabel.text = title.isEmpty ? " " : title
        elapsedLabel.text = formatTime(seconds: position)
        let remaining = max(duration - position, 0)
        remainingLabel.text = "-\(formatTime(seconds: remaining))"

        if !didAutoDismiss, duration > 0, position >= duration {
            didAutoDismiss = true
            dismissPopup(shouldShowMiniBar: false)
        }
    }

    private func formatTime(seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds.rounded())
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
#endif

