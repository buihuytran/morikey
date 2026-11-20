import Foundation

public enum TypingAction: Equatable {
    case passThrough
    case replace(deleteCount: Int, text: String)
}

public class MoriEngine {
    public var inputMethod: InputMethod
    public var toneStyle: ToneStyle
    public var isEnabled: Bool
    public var isSpellingCheckEnabled: Bool
    public var wAtWordStartAsW: Bool
    public var macroEngine: MacroEngine

    /// Currently accumulated transformed word buffer (as displayed on screen)
    public private(set) var currentWord: String = ""
    /// Raw un-transformed sequence of keystrokes (used for spelling restoration)
    public private(set) var rawWord: String = ""

    public init(
        inputMethod: InputMethod = .telex,
        toneStyle: ToneStyle = .modern,
        isEnabled: Bool = true,
        isSpellingCheckEnabled: Bool = true,
        wAtWordStartAsW: Bool = true,
        macroEngine: MacroEngine = MacroEngine()
    ) {
        self.inputMethod = inputMethod
        self.toneStyle = toneStyle
        self.isEnabled = isEnabled
        self.isSpellingCheckEnabled = isSpellingCheckEnabled
        self.wAtWordStartAsW = wAtWordStartAsW
        self.macroEngine = macroEngine
    }

    /// Resets the internal word buffer
    public func reset() {
        currentWord = ""
        rawWord = ""
    }

    /// Handles a backspace keystroke
    public func handleBackspace() {
        if !currentWord.isEmpty {
            currentWord.removeLast()
        }
        if !rawWord.isEmpty {
            rawWord.removeLast()
        }
    }

    /// Checks if a character is a delimiter (space, enter, punctuation that ends a word)
    private func isDelimiter(_ char: Character) -> Bool {
        if char.isWhitespace || char.isNewline {
            return true
        }

        switch inputMethod {
        case .telex, .simpleTelex:
            // [ ] { } are typing keys in Telex
            if char == "[" || char == "]" || char == "{" || char == "}" {
                return false
            }
            return char.isPunctuation || char.isMathSymbol

        case .vni:
            // Digits are typing keys in VNI
            if char.isNumber {
                return false
            }
            return char.isPunctuation || char.isMathSymbol

        case .viqr:
            // Special VIQR keys
            let viqrKeys: Set<Character> = ["'", "`", "?", "~", ".", "^", "+", "*", "(", "-", "0"]
            if viqrKeys.contains(char) {
                return false
            }
            return char.isPunctuation || char.isMathSymbol
        }
    }

    /// Processes an incoming character from the keyboard
    public func process(char: Character) -> TypingAction {
        guard isEnabled else {
            reset()
            return .passThrough
        }

        // Delimiters (Space, Enter, Punctuation) commit buffer, check for macros,
        // and perform smart English restoration for words like "is", "as", "this", "for", "see"...
        if isDelimiter(char) {
            // 1. Macro expansion
            if macroEngine.isEnabled, let macroReplacement = macroEngine.lookup(word: currentWord) {
                let deleteCount = currentWord.count
                reset()
                return .replace(deleteCount: deleteCount, text: macroReplacement + String(char))
            }

            // 2. Smart English Auto-Restore on word boundary
            if isSpellingCheckEnabled && currentWord != rawWord && !currentWord.isEmpty {
                if SpellingChecker.isLikelyEnglishWord(currentWord: currentWord, rawWord: rawWord) {
                    let deleteCount = currentWord.count
                    let restored = rawWord
                    reset()
                    return .replace(deleteCount: deleteCount, text: restored + String(char))
                }
            }

            reset()
            return .passThrough
        }

        rawWord.append(char)

        switch inputMethod {
        case .telex, .simpleTelex:
            // Real-time check: if rawWord starts with non-Vietnamese consonant cluster (e.g. "cl", "fr", "st", "sp", "pr", "pl")
            // or starts with a foreign letter (f, j, z) -> bypass Telex modifications!
            if isSpellingCheckEnabled {
                if SpellingChecker.hasInvalidInitialCluster(rawWord) || SpellingChecker.hasForeignInitialOrChar(rawWord) {
                    currentWord.append(char)
                    return .passThrough
                }
            }

            // 1. Try diacritics (aa -> â, aw -> ă, dd -> đ, [ -> ơ, ] -> ư, etc.)
            if let transformed = DiacriticTransform.tryTransformVowel(
                word: currentWord,
                rawWord: rawWord,
                char: char,
                inputMethod: inputMethod,
                wAtWordStartAsW: wAtWordStartAsW
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

            // 3. Normal character typing
            if char.isLetter {
                let candidate = currentWord + String(char)

                // Real-time check: if appending this letter forms an invalid coda (e.g. "look", "good", "feel")
                // or forms an invalid cluster on rawWord (e.g. "post", "text") -> restore raw English word!
                if isSpellingCheckEnabled && currentWord != rawWord {
                    if SpellingChecker.hasInvalidCoda(candidate) {
                        let deleteCount = currentWord.count
                        currentWord = rawWord
                        return .replace(deleteCount: deleteCount, text: rawWord)
                    }
                    for cluster in SpellingChecker.invalidFinalClusters {
                        if rawWord.lowercased().hasSuffix(cluster) {
                            let deleteCount = currentWord.count
                            currentWord = rawWord
                            return .replace(deleteCount: deleteCount, text: rawWord)
                        }
                    }
                }

                currentWord.append(char)
                return .passThrough
            } else {
                reset()
                return .passThrough
            }

        case .vni:
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
                    currentWord.append(char)
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
            let viqrSpecialKeys: Set<Character> = ["'", "`", "?", "~", ".", "^", "+", "*", "(", "-", "0"]
            if viqrSpecialKeys.contains(char) || char.isLetter {
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
