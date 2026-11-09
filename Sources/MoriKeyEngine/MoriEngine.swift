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

        // Punctuation, Whitespace, Newlines -> commit & pass through
        if char.isWhitespace || char.isNewline || char.isPunctuation || char.isMathSymbol {
            reset()
            return .passThrough
        }

        // Only process alphabetic characters or characters relevant to typing
        guard char.isLetter else {
            reset()
            return .passThrough
        }

        // Try 1: Diacritic transformation (aa -> â, ee -> ê, dd -> đ, aw -> ă, etc.)
        if let transformed = DiacriticTransform.tryTransformVowel(
            word: currentWord,
            char: char,
            inputMethod: inputMethod
        ) {
            let deleteCount = currentWord.count
            currentWord = transformed
            return .replace(deleteCount: deleteCount, text: transformed)
        }

        // Try 2: Tone transformation (s, f, r, x, j, z)
        if let transformed = DiacriticTransform.tryApplyTone(
            word: currentWord,
            char: char,
            toneStyle: toneStyle
        ) {
            let deleteCount = currentWord.count
            currentWord = transformed
            return .replace(deleteCount: deleteCount, text: transformed)
        }

        // Normal letter typing: append to buffer and let system display it
        currentWord.append(char)
        return .passThrough
    }
}

