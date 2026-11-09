import Foundation

public enum TypingAction: Equatable {
    case passThrough
    case replace(deleteCount: Int, text: String)
}

public class MoriEngine {
    public var inputMethod: InputMethod
    public var toneStyle: ToneStyle
    public var isEnabled: Bool

    /// Currently accumulated word buffer (as displayed on screen)
    public private(set) var currentWord: String = ""

    public init(
        inputMethod: InputMethod = .telex,
        toneStyle: ToneStyle = .modern,
        isEnabled: Bool = true
    ) {
        self.inputMethod = inputMethod
        self.toneStyle = toneStyle
        self.isEnabled = isEnabled
    }

    /// Resets the internal word buffer (e.g. on mouse click, arrow keys, focus change)
    public func reset() {
        currentWord = ""
    }

    /// Handles a backspace keystroke
    public func handleBackspace() {
        if !currentWord.isEmpty {
            currentWord.removeLast()
        }
    }

    /// Processes an incoming character from the keyboard
    public func process(char: Character) -> TypingAction {
        guard isEnabled else {
            reset()
            return .passThrough
        }

        // Space and Newlines always commit & reset buffer
        if char.isWhitespace || char.isNewline {
            reset()
            return .passThrough
        }

        switch inputMethod {
        case .telex, .simpleTelex:
            // In Telex, brackets [ and ] can be shortcuts for ơ and ư
            let isTelexKey = char.isLetter || char == "[" || char == "]" || char == "{" || char == "}"
            if !isTelexKey {
                reset()
                return .passThrough
            }

            // 1. Try diacritics (aa -> â, aw -> ă, dd -> đ, [ -> ơ, etc.)
            if let transformed = DiacriticTransform.tryTransformVowel(
                word: currentWord,
                char: char,
                inputMethod: inputMethod
            ) {
                let deleteCount = currentWord.count
                currentWord = transformed
                return .replace(deleteCount: deleteCount, text: transformed)
            }

            // 2. Try tones (s, f, r, x, j, z)
            if let transformed = DiacriticTransform.tryApplyTone(
                word: currentWord,
                char: char,
                toneStyle: toneStyle
            ) {
                let deleteCount = currentWord.count
                currentWord = transformed
                return .replace(deleteCount: deleteCount, text: transformed)
            }

            // Normal letter
            if char.isLetter {
                currentWord.append(char)
                return .passThrough
            } else {
                reset()
                return .passThrough
            }

        case .vni:
            // In VNI, letters and numbers (0-9) are valid
            if char.isNumber {
                if let transformed = VNITransform.tryTransformVNI(
                    word: currentWord,
                    char: char,
                    toneStyle: toneStyle
                ) {
                    let deleteCount = currentWord.count
                    currentWord = transformed
                    return .replace(deleteCount: deleteCount, text: transformed)
                } else {
                    // A number that doesn't transform: commits word
                    reset()
                    return .passThrough
                }
            } else if char.isLetter {
                currentWord.append(char)
                return .passThrough
            } else {
                reset()
                return .passThrough
            }

        case .viqr:
            // In VIQR: letters and special keys (' ` ? ~ . ^ + * ( - 0)
            let viqrSpecialKeys: Set<Character> = ["'", "`", "?", "~", ".", "^", "+", "*", "(", "-", "0"]
            if viqrSpecialKeys.contains(char) {
                if let transformed = VIQRTransform.tryTransformVIQR(
                    word: currentWord,
                    char: char,
                    toneStyle: toneStyle
                ) {
                    let deleteCount = currentWord.count
                    currentWord = transformed
                    return .replace(deleteCount: deleteCount, text: transformed)
                } else {
                    reset()
                    return .passThrough
                }
            } else if char.isLetter {
                // Also check if dd -> đ in VIQR
                if let transformed = VIQRTransform.tryTransformVIQR(
                    word: currentWord,
                    char: char,
                    toneStyle: toneStyle
                ) {
                    let deleteCount = currentWord.count
                    currentWord = transformed
                    return .replace(deleteCount: deleteCount, text: transformed)
                }
                currentWord.append(char)
                return .passThrough
            } else {
                reset()
                return .passThrough
            }
        }
    }
}
