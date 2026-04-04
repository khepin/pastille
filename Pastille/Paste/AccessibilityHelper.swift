import AppKit

enum AccessibilityHelper {
    static func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    static func requestAccess() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    @discardableResult
    static func ensureAccess() -> Bool {
        if isTrusted() {
            return true
        }
        requestAccess()
        return false
    }
}
