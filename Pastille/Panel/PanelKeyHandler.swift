import AppKit

@MainActor
final class PanelKeyHandler {
    private let appState: AppState
    private let onDismiss: @MainActor () -> Void
    private let onPaste: @MainActor (HistoryItem, Bool) -> Void
    private let onOpenSettings: @MainActor () -> Void
    private nonisolated(unsafe) var localMonitor: Any?

    init(
        appState: AppState,
        onDismiss: @escaping @MainActor () -> Void,
        onPaste: @escaping @MainActor (HistoryItem, Bool) -> Void,
        onOpenSettings: @escaping @MainActor () -> Void = {}
    ) {
        self.appState = appState
        self.onDismiss = onDismiss
        self.onPaste = onPaste
        self.onOpenSettings = onOpenSettings
        start()
    }

    private func start() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self else { return event }
            return self.handleKeyEvent(event)
        }
    }

    func stop() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        let keyCode = event.keyCode

        switch keyCode {
        case 43 where event.modifierFlags.contains(.command): // Cmd+,
            onOpenSettings()
            return nil

        case 53: // Escape
            onDismiss()
            return nil

        case 36: // Enter / Return
            if appState.isSearchMode {
                appState.isSearchMode = false
                return nil
            }
            print("[Pastille Key] Enter pressed, selectedItem: \(appState.selectedItem?.plainTextPreview?.prefix(40) ?? "nil")")
            if let item = appState.selectedItem {
                let plainTextOnly = event.modifierFlags.contains(.shift)
                onPaste(item, plainTextOnly)
            }
            return nil

        case 48: // Tab
            appState.isSearchMode.toggle()
            if !appState.isSearchMode {
                // Exiting search mode — keep the filtered results but go back to navigation
            }
            return nil

        case 123: // Left arrow
            if !appState.isSearchMode {
                appState.moveSelection(by: -1)
                return nil
            }
            return event

        case 124: // Right arrow
            if !appState.isSearchMode {
                appState.moveSelection(by: 1)
                return nil
            }
            return event

        case 126: // Up arrow
            if !appState.isSearchMode {
                appState.moveSelection(by: -1)
                return nil
            }
            return event

        case 125: // Down arrow
            if !appState.isSearchMode {
                appState.moveSelection(by: 1)
                return nil
            }
            return event

        case 51: // Delete / Backspace
            if appState.isSearchMode {
                if appState.searchText.isEmpty {
                    appState.isSearchMode = false
                    return nil
                }
                return event // Let TextField handle it
            }
            return event

        default:
            // Let all character keys pass through to the TextField
            return event
        }
    }

    deinit {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
    }
}
