import AppKit

enum ClipboardPaster {
    static func pasteCurrentClipboard(afterDelay delay: TimeInterval = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
            guard let commandDown = CGEvent(
                keyboardEventSource: source,
                virtualKey: 0x09,
                keyDown: true
            ) else { return }
            guard let commandUp = CGEvent(
                keyboardEventSource: source,
                virtualKey: 0x09,
                keyDown: false
            ) else { return }

            commandDown.flags = .maskCommand
            commandUp.flags = .maskCommand

            commandDown.post(tap: .cghidEventTap)
            commandUp.post(tap: .cghidEventTap)
        }
    }
}
