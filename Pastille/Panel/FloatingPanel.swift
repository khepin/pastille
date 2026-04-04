import AppKit
import SwiftUI

final class FloatingPanel: NSPanel {
    init<Content: View>(contentView: Content) {
        super.init(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Remove window chrome
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = false

        // Hide standard buttons
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true

        // Transparent background (SwiftUI provides the material)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true

        animationBehavior = .utilityWindow

        // Host the SwiftUI content
        self.contentView = NSHostingView(rootView: contentView)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
