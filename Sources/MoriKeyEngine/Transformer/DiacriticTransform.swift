import Foundation

public struct TransformResult: Equatable {
    public let text: String
    public let isUndo: Bool

    public init(text: String, isUndo: Bool = false) {
        self.text = text
        self.isUndo = isUndo
    }
}

public struct DiacriticTransform {
    public static func tryTransformVowel(
        word: String,
        rawWord: String = "",
        char: Character,
        inputMethod: InputMethod,
        wAtWordStartAsW: Bool = true
    ) -> TransformResult? {
        let isUpper = char.isUppercase
        let lowerChar = Character(char.lowercased())
        var chars = Array(word)

        // Empty buffer: user is typing the FIRST character of the word
        guard !chars.isEmpty else {
            // Standalone 'w' or 'W' at start of word
            if lowerChar == "w" {
                // If wAtWordStartAsW is true, or in Simple Telex: keep as 'w'
                if wAtWordStartAsW || inputMethod == .simpleTelex {
                    return nil
                } else if inputMethod == .telex {
                    return TransformResult(text: isUpper ? "Ư" : "ư", isUndo: false)
                }
            }

            if inputMethod == .telex || inputMethod == .simpleTelex {
                if char == "[" { return TransformResult(text: "ơ", isUndo: false) }
                if char == "]" { return TransformResult(text: "ư", isUndo: false) }
                if char == "{" { return TransformResult(text: "Ơ", isUndo: false) }
                if char == "}" { return TransformResult(text: "Ư", isUndo: false) }
            }
            return nil
        }

        let lastIdx = chars.count - 1
        let lastChar = chars[lastIdx]
        let lastLower = Character(lastChar.lowercased())
        let lastIsUpper = lastChar.isUppercase

        // 1. "dd" or "dD" -> "đ" / "Đ"
        if lowerChar == "d" {
            if lastLower == "d" {
                chars[lastIdx] = lastIsUpper ? "Đ" : "đ"
                return TransformResult(text: String(chars), isUndo: false)
            } else if lastLower == "đ" {
                // Double tap undo: 'đ' + 'd' -> "dd"
                chars[lastIdx] = lastIsUpper ? "D" : "d"
                chars.append(isUpper ? "D" : "d")
                return TransformResult(text: String(chars), isUndo: true)
            }
            return nil
        }

        // 2. Circumflex: aa -> â, ee -> ê, oo -> ô
        if lowerChar == "a" {
            let baseLast = VietnameseChar.removeTone(lastChar)
            let baseLastLower = Character(baseLast.lowercased())
            let currentTone = VietnameseChar.getTone(lastChar)

            if baseLastLower == "a" {
                let targetBase: Character = lastIsUpper ? "Â" : "â"
                chars[lastIdx] = VietnameseChar.applyTone(targetBase, tone: currentTone)
                return TransformResult(text: String(chars), isUndo: false)
            } else if baseLastLower == "â" {
                // Double tap undo: â + a -> aa
                let targetBase: Character = lastIsUpper ? "A" : "a"
                chars[lastIdx] = VietnameseChar.applyTone(targetBase, tone: currentTone)
                chars.append(isUpper ? "A" : "a")
                return TransformResult(text: String(chars), isUndo: true)
            }
        }

        if lowerChar == "e" {
            let baseLast = VietnameseChar.removeTone(lastChar)
            let baseLastLower = Character(baseLast.lowercased())
            let currentTone = VietnameseChar.getTone(lastChar)

            if baseLastLower == "e" {
                let targetBase: Character = lastIsUpper ? "Ê" : "ê"
                chars[lastIdx] = VietnameseChar.applyTone(targetBase, tone: currentTone)
                return TransformResult(text: String(chars), isUndo: false)
            } else if baseLastLower == "ê" {
                // Double tap undo
                let targetBase: Character = lastIsUpper ? "E" : "e"
                chars[lastIdx] = VietnameseChar.applyTone(targetBase, tone: currentTone)
                chars.append(isUpper ? "E" : "e")
                return TransformResult(text: String(chars), isUndo: true)
            }
        }

        if lowerChar == "o" {
            let baseLast = VietnameseChar.removeTone(lastChar)
            let baseLastLower = Character(baseLast.lowercased())
            let currentTone = VietnameseChar.getTone(lastChar)

            if baseLastLower == "o" {
                let targetBase: Character = lastIsUpper ? "Ô" : "ô"
                chars[lastIdx] = VietnameseChar.applyTone(targetBase, tone: currentTone)
                return TransformResult(text: String(chars), isUndo: false)
            } else if baseLastLower == "ô" {
                // Double tap undo: ô + o -> oo
                let targetBase: Character = lastIsUpper ? "O" : "o"
                chars[lastIdx] = VietnameseChar.applyTone(targetBase, tone: currentTone)
                chars.append(isUpper ? "O" : "o")
                return TransformResult(text: String(chars), isUndo: true)
            }
        }

        // 3. 'w' transformations (Breve & Horn):
        // aw -> ă, ow -> ơ, uw -> ư, uow -> ươ
        if lowerChar == "w" {
            // Check for 'uo' or 'ưo' -> 'ươ'
            if chars.count >= 2 {
                let secondLastIdx = chars.count - 2
                let c1 = VietnameseChar.removeTone(chars[secondLastIdx])
                let c2 = VietnameseChar.removeTone(chars[lastIdx])
                let c1Lower = Character(c1.lowercased())
                let c2Lower = Character(c2.lowercased())

                if (c1Lower == "u" || c1Lower == "ư") && c2Lower == "o" {
                    let tone = VietnameseChar.getTone(chars[lastIdx])
                    chars[secondLastIdx] = chars[secondLastIdx].isUppercase ? "Ư" : "ư"
                    let targetO: Character = chars[lastIdx].isUppercase ? "Ơ" : "ơ"
                    chars[lastIdx] = VietnameseChar.applyTone(targetO, tone: tone)
                    return TransformResult(text: String(chars), isUndo: false)
                } else if c1Lower == "ư" && c2Lower == "ơ" {
                    // Undo 'ươ' + 'w' -> 'uow'
                    let tone = VietnameseChar.getTone(chars[lastIdx])
                    chars[secondLastIdx] = chars[secondLastIdx].isUppercase ? "U" : "u"
                    let targetO: Character = chars[lastIdx].isUppercase ? "O" : "o"
                    chars[lastIdx] = VietnameseChar.applyTone(targetO, tone: tone)
                    chars.append(isUpper ? "W" : "w")
                    return TransformResult(text: String(chars), isUndo: true)
                }
            }

            let baseLast = VietnameseChar.removeTone(lastChar)
            let baseLastLower = Character(baseLast.lowercased())
            let currentTone = VietnameseChar.getTone(lastChar)

            if baseLastLower == "a" {
                let targetBase: Character = lastIsUpper ? "Ă" : "ă"
                chars[lastIdx] = VietnameseChar.applyTone(targetBase, tone: currentTone)
                return TransformResult(text: String(chars), isUndo: false)
            } else if baseLastLower == "ă" {
                // Undo ă + w -> aw
                let targetBase: Character = lastIsUpper ? "A" : "a"
                chars[lastIdx] = VietnameseChar.applyTone(targetBase, tone: currentTone)
                chars.append(isUpper ? "W" : "w")
                return TransformResult(text: String(chars), isUndo: true)
            } else if baseLastLower == "o" {
                let targetBase: Character = lastIsUpper ? "Ơ" : "ơ"
                chars[lastIdx] = VietnameseChar.applyTone(targetBase, tone: currentTone)
                return TransformResult(text: String(chars), isUndo: false)
            } else if baseLastLower == "ơ" {
                // Undo ơ + w -> ow
                let targetBase: Character = lastIsUpper ? "O" : "o"
                chars[lastIdx] = VietnameseChar.applyTone(targetBase, tone: currentTone)
                chars.append(isUpper ? "W" : "w")
                return TransformResult(text: String(chars), isUndo: true)
            } else if baseLastLower == "u" {
                let targetBase: Character = lastIsUpper ? "Ư" : "ư"
                chars[lastIdx] = VietnameseChar.applyTone(targetBase, tone: currentTone)
                return TransformResult(text: String(chars), isUndo: false)
            } else if baseLastLower == "ư" {
                // CHECK: Did this 'ư' come from a standalone 'w' or from 'u' + 'w'?
                let rawLower = rawWord.lowercased()
                if rawLower == "w" || (chars.count == 1 && !rawLower.contains("u")) {
                    // Standalone 'w' -> restore to 'w' (or 'ww')
                    return TransformResult(text: isUpper ? "W" : "w", isUndo: true)
                } else {
                    // 'u' then 'w' -> undo to "uw"
                    let targetBase: Character = lastIsUpper ? "U" : "u"
                    chars[lastIdx] = VietnameseChar.applyTone(targetBase, tone: currentTone)
                    chars.append(isUpper ? "W" : "w")
                    return TransformResult(text: String(chars), isUndo: true)
                }
            } else if inputMethod == .telex {
                // After a Vietnamese consonant (e.g. "tw" -> "tư", "sw" -> "sư", "chw" -> "chư")
                let validConsonants: Set<Character> = [
                    "b", "c", "d", "đ", "g", "h", "k", "l", "m", "n", "p", "r", "s", "t", "v", "x",
                    "B", "C", "D", "Đ", "G", "H", "K", "L", "M", "N", "P", "R", "S", "T", "V", "X"
                ]
                if validConsonants.contains(lastChar) {
                    chars.append(isUpper ? "Ư" : "ư")
                    return TransformResult(text: String(chars), isUndo: false)
                }
                return nil
            }
        }

        // 4. Bracket shortcuts in Telex: [ -> ơ, ] -> ư, { -> Ơ, } -> Ư
        if inputMethod == .telex || inputMethod == .simpleTelex {
            if char == "[" {
                if lastChar == "ơ" {
                    chars[lastIdx] = "["
                    return TransformResult(text: String(chars), isUndo: true)
                }
                chars.append("ơ")
                return TransformResult(text: String(chars), isUndo: false)
            } else if char == "]" {
                if lastChar == "ư" {
                    chars[lastIdx] = "]"
                    return TransformResult(text: String(chars), isUndo: true)
                }
                chars.append("ư")
                return TransformResult(text: String(chars), isUndo: false)
            } else if char == "{" {
                if lastChar == "Ơ" {
                    chars[lastIdx] = "{"
                    return TransformResult(text: String(chars), isUndo: true)
                }
                chars.append("Ơ")
                return TransformResult(text: String(chars), isUndo: false)
            } else if char == "}" {
                if lastChar == "Ư" {
                    chars[lastIdx] = "}"
                    return TransformResult(text: String(chars), isUndo: true)
                }
                chars.append("Ư")
                return TransformResult(text: String(chars), isUndo: false)
            }
        }

        return nil
    }

    /// Try tone key: s (acute), f (grave), r (hook), x (tilde), j (heavy), z (remove tone)
    public static func tryApplyTone(
        word: String,
        char: Character,
        toneStyle: ToneStyle
    ) -> TransformResult? {
        let lowerChar = Character(char.lowercased())
        let tone: Tone?

        switch lowerChar {
        case "s": tone = Tone.acute
        case "f": tone = Tone.grave
        case "r": tone = Tone.hook
        case "x": tone = Tone.tilde
        case "j": tone = Tone.heavy
        case "z": tone = Tone.none
        default:  tone = nil
        }

        guard let targetTone = tone else { return nil }

        // Find existing tone in word if any
        var currentTone: Tone = .none
        for c in word {
            let t = VietnameseChar.getTone(c)
            if t != .none {
                currentTone = t
                break
            }
        }

        // Double tap same tone key: e.g. "cá" + 's' -> toggle off to "cas"
        if targetTone != .none && currentTone == targetTone {
            var cleanWord = ""
            for c in word {
                cleanWord.append(VietnameseChar.removeTone(c))
            }
            cleanWord.append(char)
            return TransformResult(text: cleanWord, isUndo: true)
        }

        // Remove any existing tone first
        var baseWordChars: [Character] = []
        for c in word {
            baseWordChars.append(VietnameseChar.removeTone(c))
        }
        let cleanWord = String(baseWordChars)

        if targetTone == .none {
            // 'z' pressed -> remove tone
            if currentTone != .none {
                return TransformResult(text: cleanWord, isUndo: true)
            }
            return nil
        }

        // Locate target vowel for the tone
        guard let targetIndex = ToneRule.findToneTargetIndex(in: cleanWord, toneStyle: toneStyle) else {
            return nil
        }

        var resultChars = Array(cleanWord)
        let targetChar = resultChars[cleanWord.distance(from: cleanWord.startIndex, to: targetIndex)]
        resultChars[cleanWord.distance(from: cleanWord.startIndex, to: targetIndex)] =
            VietnameseChar.applyTone(targetChar, tone: targetTone)

        return TransformResult(text: String(resultChars), isUndo: false)
    }
}
