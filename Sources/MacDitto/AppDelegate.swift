import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let store = ClipboardStore.shared
    private var statusItem: NSStatusItem?
    private var panel: NSPanel?
    private var hotkeyMonitor: GlobalHotkeyMonitor?
    private let statusMenu = NSMenu()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        configurePanel()
        configureHotkey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyMonitor?.stop()
    }

    func togglePanel() {
        guard let panel else { return }

        if panel.isVisible {
            panel.orderOut(nil)
            return
        }

        positionPanel(panel)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func showPanel() {
        guard let panel else { return }
        if !panel.isVisible {
            togglePanel()
        } else {
            NSApp.activate(ignoringOtherApps: true)
            panel.makeKeyAndOrderFront(nil)
        }
    }

    func hidePanel() {
        panel?.orderOut(nil)
    }

    func windowWillClose(_ notification: Notification) {
        panel?.orderOut(nil)
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "MacDitto"
        item.button?.action = #selector(statusButtonPressed)
        item.button?.target = self
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        statusMenu.addItem(NSMenuItem(title: "Show Clipboard", action: #selector(showFromMenu), keyEquivalent: ""))
        statusMenu.addItem(NSMenuItem.separator())
        statusMenu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusMenu.items.forEach { $0.target = self }
        statusItem = item
    }

    private func configurePanel() {
        let rect = NSRect(x: 0, y: 0, width: 880, height: 560)
        let panel = NSPanel(
            contentRect: rect,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.title = "MacDitto"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.delegate = self

        let rootView = ContentView(onItemActivated: { [weak self] item in
            self?.store.copyAndPaste(item)
            self?.hidePanel()
        })
        .environmentObject(store)

        panel.contentView = NSHostingView(rootView: rootView)
        panel.center()
        self.panel = panel
    }

    private func configureHotkey() {
        hotkeyMonitor = GlobalHotkeyMonitor { [weak self] in
            DispatchQueue.main.async {
                self?.togglePanel()
            }
        }
        hotkeyMonitor?.start()
    }

    private func positionPanel(_ panel: NSPanel) {
        guard let screen = NSScreen.main else {
            panel.center()
            return
        }

        let visibleFrame = screen.visibleFrame
        let x = visibleFrame.midX - (panel.frame.width / 2)
        let y = visibleFrame.maxY - panel.frame.height - 60
        panel.setFrameOrigin(NSPoint(x: max(visibleFrame.minX, x), y: max(visibleFrame.minY, y)))
    }

    @objc private func statusButtonPressed() {
        guard let event = NSApp.currentEvent else {
            togglePanel()
            return
        }

        if event.type == .rightMouseUp {
            statusItem?.menu = statusMenu
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
        } else {
            togglePanel()
        }
    }

    @objc private func showFromMenu() {
        showPanel()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
