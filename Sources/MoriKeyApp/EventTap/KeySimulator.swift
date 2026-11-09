import Cocoa
import CoreGraphics

public final class KeySimulator {
    public static let moriEventTag: Int64 = 0x4D4F5249 // ASCII for "MORI"

    private static let backspaceKeyCode: CGKeyCode = 0x33 // 51

    /// Sends backspaces to delete `count` characters on screen
    public static func sendBackspaces(count: Int) {
        guard count > 0 else { return }

        let source = CGEventSource(stateID: .combinedSessionState)
        for _ in 0..<count {
            if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: backspaceKeyCode, keyDown: true) {
                keyDown.setIntegerValueField(.eventSourceUserData, value: moriEventTag)
                keyDown.post(tap: .cgSessionEventTap)
            }
            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: backspaceKeyCode, keyDown: false) {
                keyUp.setIntegerValueField(.eventSourceUserData, value: moriEventTag)
                keyUp.post(tap: .cgSessionEventTap)
            }
        }
    }

    /// Sends a Unicode string by posting keyboard events with unicode characters
    public static func sendString(_ text: String) {
        guard !text.isEmpty else { return }

        let source = CGEventSource(stateID: .combinedSessionState)
        let utf16Chars = Array(text.utf16)

        for char in utf16Chars {
            var unicodeChar = char
            if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
                keyDown.keyboardSetUnicodeString(stringLength: 1, unicodeString: &unicodeChar)
                keyDown.setIntegerValueField(.eventSourceUserData, value: moriEventTag)
                keyDown.post(tap: .cgSessionEventTap)
            }
            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
                keyUp.keyboardSetUnicodeString(stringLength: 1, unicodeString: &unicodeChar)
                keyUp.setIntegerValueField(.eventSourceUserData, value: moriEventTag)
                keyUp.post(tap: .cgSessionEventTap)
            }
        }
    }
}
