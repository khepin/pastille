import AppKit
import SwiftUI

@MainActor
final class PanelController {
    private var panel: FloatingPanel?
    private let appState: AppState
    private var keyHandler: PanelKeyHandler?
    private var clickMonitor: Any?

    /// Called when user selects an item to paste. Parameters: (item, plainTextOnly)
    var onPaste: ((HistoryItem, Bool) -> Void)?

    private let panelHeight: CGFloat = 319

    init(appState: AppState) {
        self.appState = appState
    }

    private func createPanel() {
        // Always recreate to ensure fresh SwiftUI observation tracking
        panel?.orderOut(nil)
        panel = nil

        let contentView = ClipboardHistoryView(appState: appState) { [weak self] item, plainTextOnly in
            self?.onPaste?(item, plainTextOnly)
        }

        let p = FloatingPanel(contentView: contentView)
        p.alphaValue = 0
        p.setFrame(NSRect(x: -10000, y: -10000, width: 100, height: 100), display: false)
        panel = p
    }

    func show() {
        // Reset state before creating panel so SwiftUI view initializes with clean state
        appState.searchText = ""
        appState.isSearchMode = false
        appState.selectedIndex = 0

        createPanel()
        guard let panel, let screen = NSScreen.main else { return }

        let screenRect = screen.visibleFrame
        let panelWidth = screenRect.width

        // Start below the screen
        let startFrame = NSRect(
            x: screenRect.origin.x,
            y: screenRect.origin.y - panelHeight,
            width: panelWidth,
            height: panelHeight
        )

        // End at the bottom of the visible screen
        let endFrame = NSRect(
            x: screenRect.origin.x,
            y: screenRect.origin.y,
            width: panelWidth,
            height: panelHeight
        )

        // Position off-screen first, then show
        panel.setFrame(startFrame, display: false)
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        panel.makeKey()

        // Animate in on next run loop tick to ensure frame is applied
        DispatchQueue.main.async {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().setFrame(endFrame, display: true)
                panel.animator().alphaValue = 1
            }
        }

        appState.isPanelVisible = true

        // Install keyboard handler
        keyHandler = PanelKeyHandler(appState: appState) { [weak self] in
            self?.hide()
        } onPaste: { [weak self] item, plainTextOnly in
            self?.onPaste?(item, plainTextOnly)
        }

        // Monitor clicks outside the panel
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hide()
        }
    }

    func hide() {
        guard let panel, appState.isPanelVisible else { return }
        guard let screen = NSScreen.main else {
            panel.orderOut(nil)
            appState.isPanelVisible = false
            return
        }

        // Remove monitors
        keyHandler?.stop()
        keyHandler = nil
        if let clickMonitor {
            NSEvent.removeMonitor(clickMonitor)
            self.clickMonitor = nil
        }

        let screenRect = screen.visibleFrame
        let belowScreen = NSRect(
            x: panel.frame.origin.x,
            y: screenRect.origin.y - panel.frame.height,
            width: panel.frame.width,
            height: panel.frame.height
        )

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(belowScreen, display: true)
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            Task { @MainActor in
                panel.orderOut(nil as NSWindow?)
                self?.appState.isPanelVisible = false
            }
        })
    }

    func toggle() {
        if appState.isPanelVisible {
            hide()
        } else {
            show()
        }
    }
}
