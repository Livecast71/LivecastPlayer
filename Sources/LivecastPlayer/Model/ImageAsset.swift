import Foundation
import CoreGraphics

public struct ImageAsset: Codable, Equatable, Identifiable {
    public var id: String {
        url.absoluteString + "\(size.width)x\(size.height)"
    }

    public let url: URL
    public let size: CGSize

    public init(url: URL, size: CGSize = CGSize(width: 500, height: 500)) {
        self.url = url
        self.size = size
    }
}
