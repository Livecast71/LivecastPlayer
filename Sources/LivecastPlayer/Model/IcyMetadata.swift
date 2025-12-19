import Foundation
import AVFoundation

public struct IcyMetadata: Equatable {
    public enum Key: String, CaseIterable {
        case streamTitle = "StreamTitle"
    }

    public let key: Key
    public let value: String

    public init(key: Key, value: String) {
        self.key = key
        self.value = value
    }

    init?(avItem: AVMetadataItem) {
        guard let rawKey = avItem.key as? String,
              let key = Key(rawValue: rawKey),
              let value = avItem.value as? String else { return nil }
        self.key = key
        self.value = value
    }
}
