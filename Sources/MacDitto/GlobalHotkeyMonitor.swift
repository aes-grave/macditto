import AppKit

final class GlobalHotkeyMonitor {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var hotkey: HotkeyConfiguration
    private let onTrigger: () -> Void

    init(hotkey: HotkeyConfiguration, onTrigger: @escaping () -> Void) {
        self.hotkey = hotkey
        self.onTrigger = onTrigger
    }

    func updateHotkey(_ hotkey: HotkeyConfiguration) {
        self.hotkey = hotkey
    }

    func start() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event: event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event: event)
            return event
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        globalMonitor = nil
        localMonitor = nil
    }

    private func handle(event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let required = hotkey.modifierPreset.flags

        guard modifiers == required, event.keyCode == hotkey.keyCode else {
            return
        }

        onTrigger()
    }
}
