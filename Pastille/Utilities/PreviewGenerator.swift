import AppKit

enum PreviewGenerator {
    static func textPreview(_ text: String, maxLength: Int = 200) -> String {
        if text.count <= maxLength {
            return text
        }
        return String(text.prefix(maxLength)) + "\u{2026}"
    }

    static func imageThumbnail(_ imageData: Data, maxSize: CGSize = CGSize(width: 160, height: 120)) -> NSImage? {
        guard let image = NSImage(data: imageData) else { return nil }

        let originalSize = image.size
        guard originalSize.width > 0, originalSize.height > 0 else { return nil }

        let widthRatio = maxSize.width / originalSize.width
        let heightRatio = maxSize.height / originalSize.height
        let scale = min(widthRatio, heightRatio, 1.0) // Don't upscale

        let newSize = CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )

        let thumbnail = NSImage(size: newSize)
        thumbnail.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: originalSize),
            operation: .sourceOver,
            fraction: 1.0
        )
        thumbnail.unlockFocus()
        return thumbnail
    }
}
