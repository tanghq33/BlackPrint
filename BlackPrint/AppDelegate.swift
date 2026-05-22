import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = AppSettings()
    private var dropState = DropState()
    private var statusItem: NSStatusItem?
    private var panel: NSPanel?
    private var settingsWindow: NSWindow?
    private var aboutWindow: NSWindow?

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
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
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

        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu()
            return
        }

        if panel.isVisible {
            dropState.stayOpen = false
            panel.orderOut(nil)
        } else {
            positionPanel(panel, relativeTo: button)
            panel.orderFront(nil)
        }
    }

    private func showContextMenu() {
        guard let button = statusItem?.button else { return }
        let menu = NSMenu()
        let aboutItem = NSMenuItem(title: "About", action: #selector(openAbout), keyEquivalent: "")
        aboutItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: "About")
        menu.addItem(aboutItem)
        menu.addItem(NSMenuItem(
            title: "Settings",
            action: #selector(openSettings),
            keyEquivalent: ""
        ))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: ""
        ))
        menu.popUp(positioning: nil,
                   at: NSPoint(x: 0, y: button.bounds.height + 5),
                   in: button)
    }

    @objc private func openAbout() {
        if aboutWindow == nil { setupAboutWindow() }
        NSApp.activate(ignoringOtherApps: true)
        aboutWindow?.makeKeyAndOrderFront(nil)
    }

    private func setupAboutWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "About"
        window.isReleasedWhenClosed = false
        let hosting = NSHostingView(rootView: AboutView())
        window.contentView = hosting
        let fittingSize = hosting.fittingSize
        if fittingSize.width > 0 && fittingSize.height > 0 {
            window.setContentSize(fittingSize)
        }
        window.center()
        self.aboutWindow = window
    }

    @objc private func openSettings() {
        if settingsWindow == nil { setupSettingsWindow() }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    private func setupSettingsWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.isReleasedWhenClosed = false

        let hosting = NSHostingView(
            rootView: SettingsView()
                .environment(settings)
        )
        window.contentView = hosting
        let fittingSize = hosting.fittingSize
        if fittingSize.width > 0 && fittingSize.height > 0 {
            window.setContentSize(fittingSize)
        }
        window.center()
        self.settingsWindow = window
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func positionPanel(_ panel: NSPanel, relativeTo button: NSButton) {
        guard let buttonWindow = button.window,
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
