# LivecastPlayer

A Swift framework for live stream playback, inspired by PINCHPlayer. Supports audio/video live streams, Now Playing integration, and Icy metadata.

## Requirements

- iOS 14+
- Swift 5.9+

## Installation

### Swift Package Manager

Add to your project via Xcode: File > Add Package Dependencies, or add to `Package.swift`:

```swift
dependencies: [
    .package(path: "../LivecastPlayer")
]
```

## Usage

```swift
import LivecastPlayer

let player = LivecastPlayer()

let item = LivecastItem(
    identifier: "stream-1",
    url: URL(string: "https://example.com/live.mp3")!,
    title: "Live Stream"
)

player.controller.setStream(
    item: item,
    playWhenReady: true,
    startPosition: 0
)

player.controller.play()
player.controller.pause()
player.controller.seek(to: 60)
```

Enable the audio background mode ("Audio, AirPlay, and Picture in Picture") for background playback.

### Popup player UI (bottom sheet)

You can use the built‑in popup controller to show a small player at the bottom of the screen.

```swift
import UIKit
import AVFoundation
import LivecastPlayer

final class ViewController: UIViewController {
    private let livecastPlayer = LivecastPlayer()
    private var isStreamConfigured = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // add a button that calls openPlayerTapped()
    }

    @objc
    private func openPlayerTapped() {
        if !isStreamConfigured {
            guard let url = Bundle.main.url(forResource: "game", withExtension: "mp3") else {
                return
            }

            let asset = AVURLAsset(url: url)
            let durationSeconds = CMTimeGetSeconds(asset.duration)

            let item = LivecastItem(
                identifier: "game",
                url: url,
                duration: durationSeconds,
                title: "This is a test"
            )

            Task { @MainActor in
                livecastPlayer.controller.setStream(
                    item: item,
                    playWhenReady: false,
                    startPosition: 0
                )
                livecastPlayer.controller.pause()
                presentPopup()
            }

            isStreamConfigured = true
        } else {
            Task { @MainActor in
                livecastPlayer.controller.pause()
                presentPopup()
            }
        }
    }

    private func presentPopup() {
        let popup = livecastPlayer.makePopupViewController()
        present(popup, animated: true)
    }
}
```

The popup shows:

- The current item title
- A progress bar with elapsed/remaining time
- Play / pause buttons
- ±15 seconds seek buttons
- A close button, and auto‑dismiss when playback finishes

## Structure

- **LivecastPlayer** – Main entry point
- **LivecastController** – Playback control (play, pause, seek)
- **LivecastItem** – Stream model (identifier, url, metadata)
- **Config** – AudioSessionConfig, SeekConfig, ImageConfig
- **State** – LivecastState, PlaybackState, position info
