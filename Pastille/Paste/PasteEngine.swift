import AppKit
import CoreGraphics

@MainActor
final class PasteEngine {
    private let clipboardMonitor: ClipboardMonitor
    private let panelController: PanelController
    private var targetAppPID: pid_t?

    init(clipboardMonitor: ClipboardMonitor, panelController: PanelController) {
        self.clipboardMonitor = clipboardMonitor
        self.panelController = panelController
    }

    /// Call before showing the panel to remember which app should receive the paste
    func captureTargetApp() {
        if let app = NSWorkspace.shared.frontmostApplication, app.bundleIdentifier != Bundle.main.bundleIdentifier {
            targetAppPID = app.processIdentifier
            print("[Pastille Paste] Captured target app: \(app.localizedName ?? "?") (PID \(app.processIdentifier))")
        }
    }

    func paste(item: HistoryItem, plainTextOnly: Bool) {
        print("[Pastille Paste] paste() called for item: \"\(item.plainTextPreview?.prefix(40) ?? "nil")\" plainTextOnly=\(plainTextOnly)")
        print("[Pastille Paste] item.contents count: \(item.contents.count)")

        restoreToClipboard(item: item, plainTextOnly: plainTextOnly)

        let pid = targetAppPID
        panelController.hide()

        // Re-activate the target app, then simulate Cmd+V after it has focus
        if let pid, let app = NSRunningApplication(processIdentifier: pid) {
            app.activate()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [pid] in
            print("[Pastille Paste] Simulating Cmd+V to PID: \(pid.map(String.init) ?? "session")")
            Self.simulatePaste(toPID: pid)
        }
    }

    private func restoreToClipboard(item: HistoryItem, plainTextOnly: Bool) {
        let pasteboard = NSPasteboard.general

        // Tell the monitor to ignore this change
        clipboardMonitor.ignoreNextChange = true

        pasteboard.clearContents()

        if plainTextOnly {
            // Write only plain text
            if let plainText = item.plainTextPreview {
                // Try to get the full plain text from contents first
                let fullText = item.contents
                    .first(where: { $0.type == NSPasteboard.PasteboardType.string.rawValue })
                    .flatMap { $0.value }
                    .flatMap { String(data: $0, encoding: .utf8) }
                    ?? plainText

                pasteboard.setString(fullText, forType: .string)
            }
        } else {
            // Restore all content types
            let pasteboardItem = NSPasteboardItem()
            for content in item.contents {
                if let data = content.value {
                    pasteboardItem.setData(data, forType: NSPasteboard.PasteboardType(content.type))
                }
            }
            pasteboard.writeObjects([pasteboardItem])
        }
    }

    nonisolated private static func simulatePaste(toPID pid: pid_t?) {
        let trusted = AccessibilityHelper.isTrusted()
        print("[Pastille Paste] AXIsProcessTrusted: \(trusted)")
        guard trusted else {
            AccessibilityHelper.requestAccess()
            return
        }

        let source = CGEventSource(stateID: .combinedSessionState)

        // Virtual key code 9 = "V" on QWERTY
        let vKeyCode: CGKeyCode = 9

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        else { return }

        // Command modifier
        let cmdFlag = CGEventFlags.maskCommand
        keyDown.flags = cmdFlag
        keyUp.flags = cmdFlag

        if let pid {
            keyDown.postToPid(pid)
            keyUp.postToPid(pid)
        } else {
            keyDown.post(tap: .cgSessionEventTap)
            keyUp.post(tap: .cgSessionEventTap)
        }
    }
}
