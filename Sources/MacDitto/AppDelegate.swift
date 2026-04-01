import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let store = ClipboardStore.shared
    private let settings = AppSettings.shared
    private var statusItem: NSStatusItem?
    private var panel: NSPanel?
    private var settingsWindow: NSWindow?
    private var hotkeyMonitor: GlobalHotkeyMonitor?
    private let statusMenu = NSMenu()
    private var previousApplication: NSRunningApplication?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        configurePanel()
        configureSettingsWindow()
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

        capturePreviousApplication()
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
        statusMenu.addItem(NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ","))
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
            self?.paste(item)
        }, onDismiss: { [weak self] in
            self?.hidePanel()
        })
        .environmentObject(store)
        .environmentObject(settings)

        panel.contentView = NSHostingView(rootView: rootView)
        panel.center()
        self.panel = panel
    }

    private func configureHotkey() {
        hotkeyMonitor = GlobalHotkeyMonitor(hotkey: settings.hotkey) { [weak self] in
            DispatchQueue.main.async {
                self?.togglePanel()
            }
        }
        hotkeyMonitor?.start()

        settings.$hotkey
            .sink { [weak self] hotkey in
                self?.hotkeyMonitor?.updateHotkey(hotkey)
            }
            .store(in: &cancellables)
    }

    private func configureSettingsWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 220),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "MacDitto Settings"
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.center()
        window.contentViewController = AppKitSettingsViewController()
        settingsWindow = window
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

    private func capturePreviousApplication() {
        let current = NSWorkspace.shared.frontmostApplication
        if current?.bundleIdentifier != Bundle.main.bundleIdentifier {
            previousApplication = current
        }
    }

    private func paste(_ item: ClipboardItem) {
        store.copyToClipboard(item)
        hidePanel()

        guard let previousApplication else {
            ClipboardPaster.pasteCurrentClipboard(afterDelay: 0.1)
            return
        }

        previousApplication.activate(options: [.activateIgnoringOtherApps])
        ClipboardPaster.pasteCurrentClipboard(afterDelay: 0.18)
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

    @objc private func showSettings() {
        if panel?.isVisible == true {
            panel?.orderOut(nil)
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        settingsWindow?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
