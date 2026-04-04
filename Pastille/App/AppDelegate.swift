import AppKit
import SwiftUI
import SwiftData

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var clipboardMonitor: ClipboardMonitor!
    private var storageManager: StorageManager!
    private var panelController: PanelController!
    private var hotkeyManager: HotkeyManager!
    private var pasteEngine: PasteEngine!
    private var settingsWindow: NSWindow?

    let appState = AppState()

    private var historyCountItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupStorage()
        setupClipboardMonitor()
        setupPanel()
        setupHotkeys()
        setupPasteEngine()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "clipboard",
                accessibilityDescription: "Pastille"
            )
        }

        let menu = NSMenu()
        historyCountItem = NSMenuItem(title: "No items in history", action: nil, keyEquivalent: "")
        historyCountItem.isEnabled = false
        menu.addItem(historyCountItem)

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(
            title: "Settings\u{2026}",
            action: #selector(openSettings),
            keyEquivalent: ","
        ))

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(
            title: "Quit Pastille",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        statusItem.menu = menu
    }

    // MARK: - Storage

    private func setupStorage() {
        storageManager = StorageManager()
    }

    // MARK: - Clipboard Monitor

    private func setupClipboardMonitor() {
        clipboardMonitor = ClipboardMonitor()
        clipboardMonitor.onNewClip = { [weak self] bundleId, appName, contents in
            guard let self else { return }
            self.storageManager.insert(
                bundleId: bundleId,
                appName: appName,
                contents: contents
            )
            self.storageManager.pruneIfNeeded(
                maxCount: UserDefaults.standard.object(forKey: "maxHistoryCount") as? Int ?? 1000
            )
            self.refreshHistory()
        }
        clipboardMonitor.start()
    }

    // MARK: - Panel

    private func setupPanel() {
        panelController = PanelController(appState: appState)
    }

    // MARK: - Hotkeys

    private func setupHotkeys() {
        hotkeyManager = HotkeyManager { [weak self] in
            self?.togglePanel()
        }
    }

    // MARK: - Paste Engine

    private func setupPasteEngine() {
        pasteEngine = PasteEngine(
            clipboardMonitor: clipboardMonitor,
            panelController: panelController
        )
        panelController.onPaste = { [weak self] item, plainTextOnly in
            item.timestamp = Date()
            try? self?.storageManager.modelContainer.mainContext.save()
            self?.pasteEngine.paste(item: item, plainTextOnly: plainTextOnly)
        }
    }

    // MARK: - Actions

    @objc private func togglePanel() {
        if appState.isPanelVisible {
            panelController.hide()
        } else {
            pasteEngine.captureTargetApp()
            refreshHistory()
            panelController.show()
        }
    }

    @objc private func openSettings() {
        if let settingsWindow, settingsWindow.isVisible {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }

        let settingsView = SettingsView()
            .environment(appState)
        let controller = NSHostingController(rootView: settingsView)
        let window = NSWindow(contentViewController: controller)
        window.title = "Pastille Settings"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 520, height: 400))
        window.center()
        window.makeKeyAndOrderFront(nil)
        self.settingsWindow = window
        NSApp.activate()
    }

    // MARK: - Data

    func refreshHistory() {
        appState.historyItems = storageManager.fetchAll()
        let count = appState.historyItems.count
        historyCountItem?.title = count == 0
            ? "No items in history"
            : "\(count) item\(count == 1 ? "" : "s") in history"
    }
}
