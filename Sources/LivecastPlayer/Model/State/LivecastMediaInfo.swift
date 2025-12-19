import Foundation

public struct LivecastMediaInfo: Equatable {
    public var currentItem: LivecastItem?
    public var detectedMetadata: [KeySpaceMetadata]?
}
