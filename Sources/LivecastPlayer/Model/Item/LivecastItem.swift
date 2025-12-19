import Foundation

public struct LivecastItem: Codable, Equatable {
    public let identifier: String
    public let url: URL
    public let duration: TimeInterval?
    public let originalMetadata: LivecastItemMetadata
    public var metadata: LivecastItemMetadata

    public init(
        identifier: String,
        url: URL,
        duration: TimeInterval? = nil,
        title: String,
        artist: String? = nil,
        coverImage: ImageAsset? = nil
    ) {
        self.identifier = identifier
        self.url = url
        self.duration = duration
        let meta = LivecastItemMetadata(title: title, artist: artist, coverImage: coverImage)
        self.originalMetadata = meta
        self.metadata = meta
    }
}
