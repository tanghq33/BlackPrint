import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = AppSettings()
    private var dropState = DropState()
    private var statusItem: NSStatusItem?
    private var panel: NSPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPanel()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: "printer.fill", accessibilityDescription: "BlackPrint")
        button.image?.isTemplate = true
        button.action = #selector(togglePanel)
        button.target = self
    }

    // MARK: - Panel

    private func setupPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 220),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovable = false
        panel.isMovableByWindowBackground = false
        panel.backgroundColor = .clear
        panel.isOpaque = false

        let hosting = NSHostingView(
            rootView: ContentView()
                .environment(settings)
                .environment(dropState)
        )
        panel.contentView = PanelContentView(hostingView: hosting, dropState: dropState)
        self.panel = panel
        dropState.closePanel = { [weak panel, weak self] in
            panel?.orderOut(nil)
            self?.dropState.stayOpen = false
        }
    }

    // MARK: - Toggle

    @objc private func togglePanel() {
        guard let panel, let button = statusItem?.button else { return }

        if panel.isVisible {
            dropState.stayOpen = false
            panel.orderOut(nil)
        } else {
            positionPanel(relativeTo: button)
            panel.orderFront(nil)
        }
    }

    private func positionPanel(relativeTo button: NSButton) {
        guard let panel,
              let buttonWindow = button.window,
              let screen = buttonWindow.screen ?? NSScreen.main else { return }

        let buttonFrame = buttonWindow.convertToScreen(button.frame)
        let panelWidth = panel.frame.width
        let panelHeight = panel.frame.height

        var x = buttonFrame.midX - panelWidth / 2
        let y = buttonFrame.minY - panelHeight + 4

        x = max(screen.visibleFrame.minX + 8,
                min(x, screen.visibleFrame.maxX - panelWidth - 8))

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
