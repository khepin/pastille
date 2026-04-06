import Carbon.HIToolbox
import AppKit
import CoreServices

// MARK: - KeyCombo

struct KeyCombo: Codable, Equatable, Sendable {
    let carbonKeyCode: Int
    let carbonModifiers: Int

    init(carbonKeyCode: Int, carbonModifiers: Int) {
        self.carbonKeyCode = carbonKeyCode
        self.carbonModifiers = NSEvent.ModifierFlags(carbonValue: carbonModifiers).carbonValue
    }

    init(key: Int, modifiers: NSEvent.ModifierFlags) {
        self.carbonKeyCode = key
        self.carbonModifiers = modifiers.carbonValue
    }

    init?(event: NSEvent) {
        guard event.type == .keyDown || event.type == .keyUp else { return nil }
        self.carbonKeyCode = Int(event.keyCode)
        self.carbonModifiers = event.modifierFlags
            .intersection(.deviceIndependentFlagsMask)
            .subtracting([.capsLock, .numericPad, .function])
            .carbonValue
    }

    var modifiers: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(carbonValue: carbonModifiers)
    }
}

extension KeyCombo {
    @MainActor var displayString: String {
        let modString = modifiers.symbolicDescription
        let keyString = keyName(for: carbonKeyCode)
        return modString + keyString
    }

    @MainActor private func keyName(for keyCode: Int) -> String {
        if let special = specialKeyDescriptions[keyCode] {
            return special
        }
        // Use keyboard layout to translate key code to character
        guard
            let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
            let layoutDataPointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else {
            return "?"
        }

        let layoutData = unsafeBitCast(layoutDataPointer, to: CFData.self)
        let keyLayout = unsafeBitCast(CFDataGetBytePtr(layoutData), to: UnsafePointer<UCKeyboardLayout>.self)
        var deadKeyState: UInt32 = 0
        let maxLength = 4
        var length = 0
        var characters = [UniChar](repeating: 0, count: maxLength)

        let error = UCKeyTranslate(
            keyLayout,
            UInt16(keyCode),
            UInt16(kUCKeyActionDisplay),
            0,
            UInt32(LMGetKbdType()),
            OptionBits(kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState,
            maxLength,
            &length,
            &characters
        )

        guard error == noErr else { return "?" }
        return String(utf16CodeUnits: characters, count: length).uppercased()
    }
}

private let specialKeyDescriptions: [Int: String] = [
    kVK_Return: "↩",
    kVK_Delete: "⌫",
    kVK_ForwardDelete: "⌦",
    kVK_End: "↘",
    kVK_Escape: "⎋",
    kVK_Help: "?⃝",
    kVK_Home: "↖",
    kVK_Space: "Space",
    kVK_Tab: "⇥",
    kVK_PageUp: "⇞",
    kVK_PageDown: "⇟",
    kVK_UpArrow: "↑",
    kVK_RightArrow: "→",
    kVK_DownArrow: "↓",
    kVK_LeftArrow: "←",
    kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4",
    kVK_F5: "F5", kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8",
    kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
    kVK_F13: "F13", kVK_F14: "F14", kVK_F15: "F15", kVK_F16: "F16",
    kVK_F17: "F17", kVK_F18: "F18", kVK_F19: "F19", kVK_F20: "F20",
]

// MARK: - NSEvent.ModifierFlags Carbon conversion

extension NSEvent.ModifierFlags {
    // Carbon modifier flag values
    private static let carbonFunctionKey = 1 << 17

    var carbonValue: Int {
        var carbon = 0
        if contains(.control) { carbon |= controlKey }
        if contains(.option) { carbon |= optionKey }
        if contains(.shift) { carbon |= shiftKey }
        if contains(.command) { carbon |= cmdKey }
        if contains(.function) { carbon |= Self.carbonFunctionKey }
        return carbon
    }

    init(carbonValue: Int) {
        self.init()
        if carbonValue & controlKey == controlKey { insert(.control) }
        if carbonValue & optionKey == optionKey { insert(.option) }
        if carbonValue & shiftKey == shiftKey { insert(.shift) }
        if carbonValue & cmdKey == cmdKey { insert(.command) }
        if carbonValue & Self.carbonFunctionKey == Self.carbonFunctionKey { insert(.function) }
    }

    var symbolicDescription: String {
        var s = ""
        if contains(.control) { s += "⌃" }
        if contains(.option) { s += "⌥" }
        if contains(.shift) { s += "⇧" }
        if contains(.command) { s += "⌘" }
        if contains(.function) { s += "🌐\u{FE0E}" }
        return s
    }
}

// MARK: - Persistence

enum HotkeyDefaults {
    private static let key = "Pastille_showPanelShortcut"
    // Migrate from the old KeyboardShortcuts key if present
    private static let legacyKey = "KeyboardShortcuts_showPanel"

    static let defaultCombo = KeyCombo(key: kVK_ANSI_V, modifiers: [.command, .shift])

    static func load() -> KeyCombo {
        // Try new key first
        if let data = UserDefaults.standard.data(forKey: key),
           let combo = try? JSONDecoder().decode(KeyCombo.self, from: data) {
            return combo
        }
        // Try legacy key
        if let json = UserDefaults.standard.string(forKey: legacyKey),
           let data = json.data(using: .utf8),
           let combo = try? JSONDecoder().decode(KeyCombo.self, from: data) {
            // Migrate
            save(combo)
            UserDefaults.standard.removeObject(forKey: legacyKey)
            return combo
        }
        return defaultCombo
    }

    static func save(_ combo: KeyCombo?) {
        if let combo, let data = try? JSONEncoder().encode(combo) {
            UserDefaults.standard.set(data, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
        NotificationCenter.default.post(name: .hotkeyChanged, object: nil)
    }
}

extension Notification.Name {
    static let hotkeyChanged = Notification.Name("Pastille_hotkeyChanged")
}

// MARK: - GlobalHotkeyManager

private func carbonEventHandler(
    _: EventHandlerCallRef?,
    event: EventRef?,
    _: UnsafeMutableRawPointer?
) -> OSStatus {
    GlobalHotkeyManager.handleCarbonEvent(event)
}

@MainActor
final class GlobalHotkeyManager {
    private var onKeyDown: () -> Void
    nonisolated(unsafe) private var hotKeyRef: EventHotKeyRef?
    nonisolated(unsafe) private var eventHandlerRef: EventHandlerRef?
    nonisolated(unsafe) private var observer: (any NSObjectProtocol)?

    // "PSTL" as UInt32
    nonisolated static let _signature: UInt32 = 0x5053544C
    nonisolated(unsafe) private static var currentHandler: (() -> Void)?

    init(onKeyDown: @escaping () -> Void) {
        self.onKeyDown = onKeyDown
        installEventHandler()
        register(HotkeyDefaults.load())
        observer = NotificationCenter.default.addObserver(
            forName: .hotkeyChanged, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.reregister()
            }
        }
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        Self.currentHandler = nil
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func installEventHandler() {
        var eventTypes = [
            EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )
        ]
        var handler: EventHandlerRef?
        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            carbonEventHandler,
            eventTypes.count,
            &eventTypes,
            nil,
            &handler
        )
        if status == noErr {
            eventHandlerRef = handler
        }
    }

    private func register(_ combo: KeyCombo) {
        unregister()
        Self.currentHandler = onKeyDown
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(combo.carbonKeyCode),
            UInt32(combo.carbonModifiers),
            EventHotKeyID(signature: Self._signature, id: 1),
            GetEventDispatcherTarget(),
            0,
            &ref
        )
        if status == noErr {
            hotKeyRef = ref
        }
    }

    private func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        Self.currentHandler = nil
    }

    private func reregister() {
        register(HotkeyDefaults.load())
    }

    nonisolated static func handleCarbonEvent(_ event: EventRef?) -> OSStatus {
        guard let event else { return OSStatus(eventNotHandledErr) }

        var hotKeyID = EventHotKeyID()
        let error = GetEventParameter(
            event,
            UInt32(kEventParamDirectObject),
            UInt32(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard error == noErr, hotKeyID.signature == _signature else {
            return OSStatus(eventNotHandledErr)
        }

        if let handler = currentHandler {
            DispatchQueue.main.async {
                handler()
            }
        }
        return noErr
    }
}
