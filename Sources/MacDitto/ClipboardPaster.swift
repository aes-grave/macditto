import AppKit

enum ClipboardPaster {
    static func pasteCurrentClipboard() {
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
