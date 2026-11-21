import Cocoa
import CoreGraphics

public final class KeySimulator {
    public static let moriEventTag: Int64 = 0x4D4F5249 // ASCII for "MORI"

    private static let backspaceKeyCode: CGKeyCode = 0x33 // 51
    private static let forwardDeleteKeyCode: CGKeyCode = 0x75 // 117 (Forward Delete)

    /// Replaces `deleteCount` characters on screen with `text`.
    /// When `fixBrowserAutocomplete` is true, sends Forward Delete (0x75) first to cancel/clear inline autocomplete suggestions in browsers (Safari, Chrome...).
    public static func replace(deleteCount: Int, text: String, fixBrowserAutocomplete: Bool = false) {
        guard deleteCount > 0 || !text.isEmpty else { return }

        let source = CGEventSource(stateID: .hidSystemState)

        if fixBrowserAutocomplete {
            if let delDown = CGEvent(keyboardEventSource: source, virtualKey: forwardDeleteKeyCode, keyDown: true) {
                delDown.setIntegerValueField(.eventSourceUserData, value: moriEventTag)
                delDown.post(tap: .cghidEventTap)
            }
            if let delUp = CGEvent(keyboardEventSource: source, virtualKey: forwardDeleteKeyCode, keyDown: false) {
                delUp.setIntegerValueField(.eventSourceUserData, value: moriEventTag)
                delUp.post(tap: .cghidEventTap)
            }
            usleep(1500)
        }

        sendBackspaces(count: deleteCount)
        if fixBrowserAutocomplete {
            usleep(1000)
        }
        sendString(text)
    }

    /// Sends backspaces to delete `count` characters on screen
    public static func sendBackspaces(count: Int) {
        guard count > 0 else { return }

        let source = CGEventSource(stateID: .hidSystemState)
        for _ in 0..<count {
            if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: backspaceKeyCode, keyDown: true) {
                keyDown.setIntegerValueField(.eventSourceUserData, value: moriEventTag)
                keyDown.post(tap: .cghidEventTap)
            }
            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: backspaceKeyCode, keyDown: false) {
                keyUp.setIntegerValueField(.eventSourceUserData, value: moriEventTag)
                keyUp.post(tap: .cghidEventTap)
            }
            usleep(500)
        }
    }

    /// Sends a Unicode string by posting keyboard events with unicode characters
    public static func sendString(_ text: String) {
        guard !text.isEmpty else { return }

        let source = CGEventSource(stateID: .hidSystemState)
        var utf16Chars = Array(text.utf16)

        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
            keyDown.keyboardSetUnicodeString(stringLength: utf16Chars.count, unicodeString: &utf16Chars)
            keyDown.setIntegerValueField(.eventSourceUserData, value: moriEventTag)
            keyDown.post(tap: .cghidEventTap)
        }
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
            keyUp.keyboardSetUnicodeString(stringLength: utf16Chars.count, unicodeString: &utf16Chars)
            keyUp.setIntegerValueField(.eventSourceUserData, value: moriEventTag)
            keyUp.post(tap: .cghidEventTap)
        }
    }
}
