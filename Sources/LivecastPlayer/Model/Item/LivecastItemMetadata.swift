import Foundation

public struct LivecastItemMetadata: Codable, Equatable {
    public let title: String
    public let artist: String?
    public let coverImage: ImageAsset?

    public init(title: String, artist: String? = nil, coverImage: ImageAsset? = nil) {
        self.title = title
        self.artist = artist
        self.coverImage = coverImage
    }
}
