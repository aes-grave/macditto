import AppKit

final class GlobalHotkeyMonitor {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private let settings: AppSettings
    private let onTrigger: () -> Void

    init(settings: AppSettings, onTrigger: @escaping () -> Void) {
        self.settings = settings
        self.onTrigger = onTrigger
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
        let required = settings.hotkey.modifierPreset.flags

        guard modifiers == required, event.keyCode == settings.hotkey.keyCode else {
            return
        }

        onTrigger()
    }
}
