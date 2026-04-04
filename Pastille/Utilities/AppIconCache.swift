import AppKit

@MainActor
final class AppIconCache {
    static let shared = AppIconCache()

    private let cache = NSCache<NSString, NSImage>()

    private init() {
        cache.countLimit = 100
    }

    func icon(for bundleIdentifier: String) -> NSImage? {
        let key = bundleIdentifier as NSString

        if let cached = cache.object(forKey: key) {
            return cached
        }

        guard let url = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: bundleIdentifier
        ) else { return nil }

        let icon = NSWorkspace.shared.icon(forFile: url.path)
        cache.setObject(icon, forKey: key)
        return icon
    }
}
