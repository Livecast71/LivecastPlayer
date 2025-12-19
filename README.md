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

## Structure

- **LivecastPlayer** – Main entry point
- **LivecastController** – Playback control (play, pause, seek)
- **LivecastItem** – Stream model (identifier, url, metadata)
- **Config** – AudioSessionConfig, SeekConfig, ImageConfig
- **State** – LivecastState, PlaybackState, position info
