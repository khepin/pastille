import AppKit

@MainActor
final class ClipboardMonitor {
    private let pasteboard = NSPasteboard.general
    private(set) var lastChangeCount: Int
    private var timer: Timer?

    /// Set to true before writing to pasteboard to prevent re-capture
    var ignoreNextChange = false

    /// Set of bundle identifiers to exclude from monitoring
    var excludedBundleIdentifiers: Set<String> = {
        var set: Set<String> = []
        if let bundleId = Bundle.main.bundleIdentifier {
            set.insert(bundleId)
        }
        if let excluded = UserDefaults.standard.array(forKey: "excludedApps") as? [String] {
            set.formUnion(excluded)
        }
        return set
    }()

    var onNewClip: ((_ bundleId: String?, _ appName: String?, _ contents: [(type: String, data: Data)]) -> Void)?

    init() {
        lastChangeCount = pasteboard.changeCount
    }

    func start() {
        let interval = UserDefaults.standard.double(forKey: "pollingInterval")
        let pollingInterval = interval > 0 ? interval : 0.5

        timer = Timer.scheduledTimer(
            timeInterval: pollingInterval,
            target: self,
            selector: #selector(checkForChanges),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func restart() {
        stop()
        start()
    }

    @objc private func checkForChanges() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        if ignoreNextChange {
            ignoreNextChange = false
            return
        }

        // Identify source app
        let frontApp = NSWorkspace.shared.frontmostApplication
        let bundleId = frontApp?.bundleIdentifier
        let appName = frontApp?.localizedName

        // Check exclusion
        if let bid = bundleId, excludedBundleIdentifiers.contains(bid) {
            return
        }

        // Process pasteboard items
        guard let items = pasteboard.pasteboardItems else { return }

        var allContents: [(type: String, data: Data)] = []

        for item in items {
            // Skip concealed items (password managers etc.)
            if PasteboardTypes.isConcealed(item) {
                print("[Pastille] Skipping concealed item")
                return
            }

            // Log all types on the pasteboard for debugging
            print("[Pastille] Pasteboard types from \(appName ?? "unknown"): \(item.types.map(\.rawValue))")

            for type in item.types {
                if PasteboardTypes.shouldCapture(type),
                   let data = item.data(forType: type) {
                    allContents.append((type: type.rawValue, data: data))
                    if type == .string, let text = String(data: data, encoding: .utf8) {
                        print("[Pastille] Captured text: \(String(text.prefix(100)))")
                    } else {
                        print("[Pastille] Captured type: \(type.rawValue) (\(data.count) bytes)")
                    }
                }
            }
        }

        guard !allContents.isEmpty else {
            print("[Pastille] No supported types found, skipping")
            return
        }

        onNewClip?(bundleId, appName, allContents)
    }
}
