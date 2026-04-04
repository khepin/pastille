import KeyboardShortcuts

@MainActor
final class HotkeyManager {
    private let onToggle: @MainActor () -> Void

    init(onToggle: @escaping @MainActor () -> Void) {
        self.onToggle = onToggle

        KeyboardShortcuts.onKeyDown(for: .showPanel) { [weak self] in
            Task { @MainActor in
                self?.onToggle()
            }
        }
    }
}
