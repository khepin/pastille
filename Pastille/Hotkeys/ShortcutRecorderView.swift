import SwiftUI
import AppKit
import Carbon.HIToolbox

struct ShortcutRecorderView: View {
    let label: String

    var body: some View {
        LabeledContent {
            ShortcutRecorderNSView()
                .frame(width: 130, height: 24)
        } label: {
            Text(label)
        }
    }
}

private struct ShortcutRecorderNSView: NSViewRepresentable {
    func makeNSView(context: Context) -> RecorderSearchField {
        RecorderSearchField()
    }

    func updateNSView(_ nsView: RecorderSearchField, context: Context) {}
}

@MainActor
final class RecorderSearchField: NSSearchField, NSSearchFieldDelegate {
    private var eventMonitor: Any?
    private var savedCancelButton: NSButtonCell?
    nonisolated(unsafe) private var observer: (any NSObjectProtocol)?

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.width = 130
        return size
    }

    override init(frame: NSRect) {
        super.init(frame: NSRect(x: 0, y: 0, width: 130, height: 24))
        delegate = self
        placeholderString = "Record Shortcut"
        alignment = .center
        (cell as? NSSearchFieldCell)?.searchButtonCell = nil
        wantsLayer = true
        setContentHuggingPriority(.defaultHigh, for: .vertical)
        setContentHuggingPriority(.defaultHigh, for: .horizontal)
        savedCancelButton = (cell as? NSSearchFieldCell)?.cancelButtonCell
        refreshDisplay()

        observer = NotificationCenter.default.addObserver(
            forName: .hotkeyChanged, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.refreshDisplay()
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    @MainActor
    private func refreshDisplay() {
        let combo = HotkeyDefaults.load()
        stringValue = combo.displayString
        showCancelButton(!stringValue.isEmpty)
    }

    private func showCancelButton(_ show: Bool) {
        (cell as? NSSearchFieldCell)?.cancelButtonCell = show ? savedCancelButton : nil
    }

    private func endRecording() {
        stopMonitoring()
        placeholderString = "Record Shortcut"
        showCancelButton(!stringValue.isEmpty)
        (currentEditor() as? NSTextView)?.insertionPointColor = .labelColor
        layer?.borderWidth = 0
    }

    private func stopMonitoring() {
        guard let eventMonitor else { return }
        NSEvent.removeMonitor(eventMonitor)
        self.eventMonitor = nil
    }

    func controlTextDidChange(_ obj: Notification) {
        if stringValue.isEmpty {
            HotkeyDefaults.save(HotkeyDefaults.defaultCombo)
        }
        showCancelButton(!stringValue.isEmpty)
        if stringValue.isEmpty {
            window?.makeFirstResponder(self)
        }
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        endRecording()
    }

    override func becomeFirstResponder() -> Bool {
        guard window != nil else { return false }
        let result = super.becomeFirstResponder()
        guard result else { return false }

        placeholderString = "Press Shortcut"
        showCancelButton(!stringValue.isEmpty)
        (currentEditor() as? NSTextView)?.insertionPointColor = .clear
        layer?.borderColor = NSColor.controlAccentColor.cgColor
        layer?.borderWidth = 2
        layer?.cornerRadius = 6

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseUp, .rightMouseUp]) { [weak self] event in
            guard let self else { return nil }

            // Handle clicks outside the field
            if event.type == .leftMouseUp || event.type == .rightMouseUp {
                let point = self.convert(event.locationInWindow, from: nil)
                if !self.bounds.insetBy(dx: -3, dy: -3).contains(point) {
                    self.window?.makeFirstResponder(nil)
                    return event
                }
                return nil
            }

            guard event.type == .keyDown else { return nil }

            let flags = event.modifierFlags
                .intersection(.deviceIndependentFlagsMask)
                .subtracting([.capsLock, .numericPad])

            // Tab without modifiers: blur and bubble
            if flags.subtracting(.function).isEmpty && event.specialKey == .tab {
                self.window?.makeFirstResponder(nil)
                return event
            }

            // Escape: cancel
            if flags.subtracting(.function).isEmpty && event.keyCode == UInt16(kVK_Escape) {
                self.window?.makeFirstResponder(nil)
                return nil
            }

            // Delete/Backspace: clear shortcut, reset to default
            if flags.subtracting(.function).isEmpty &&
                (event.specialKey == .delete || event.specialKey == .deleteForward || event.specialKey == .backspace) {
                (self.cell as? NSSearchFieldCell)?.cancelButtonCell?.performClick(self)
                return nil
            }

            // Require at least one real modifier (not just shift/function)
            guard !flags.subtracting([.shift, .function]).isEmpty ||
                  event.specialKey?.isFunctionKey == true else {
                NSSound.beep()
                return nil
            }

            guard let combo = KeyCombo(event: event) else {
                NSSound.beep()
                return nil
            }

            self.stringValue = combo.displayString
            self.showCancelButton(true)
            HotkeyDefaults.save(combo)
            self.window?.makeFirstResponder(nil)
            return nil
        }

        return true
    }
}

private extension NSEvent.SpecialKey {
    var isFunctionKey: Bool {
        let functionKeys: Set<NSEvent.SpecialKey> = [
            .f1, .f2, .f3, .f4, .f5, .f6, .f7, .f8, .f9, .f10,
            .f11, .f12, .f13, .f14, .f15, .f16, .f17, .f18, .f19, .f20,
        ]
        return functionKeys.contains(self)
    }
}
