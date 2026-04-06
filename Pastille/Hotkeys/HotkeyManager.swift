@MainActor
final class HotkeyManager {
    private let hotkeyManager: GlobalHotkeyManager

    init(onToggle: @escaping @MainActor () -> Void) {
        hotkeyManager = GlobalHotkeyManager(onKeyDown: onToggle)
    }
}
