import Foundation

public struct DiacriticTransform {
    public static func tryTransformVowel(
        word: String,
        char: Character,
        inputMethod: InputMethod
    ) -> String? {
        let isUpper = char.isUppercase
        let lowerChar = Character(char.lowercased())
        var chars = Array(word)
        guard !chars.isEmpty else {
            // Standalone 'w' or 'W'
            if lowerChar == "w" && inputMethod == .telex {
                return isUpper ? "Ư" : "ư"
            }
            if inputMethod == .telex || inputMethod == .simpleTelex {
                if char == "[" { return "ơ" }
                if char == "]" { return "ư" }
                if char == "{" { return "Ơ" }
                if char == "}" { return "Ư" }
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
                // If last is 'd', turn into 'đ'
                chars[lastIdx] = lastIsUpper ? "Đ" : "đ"
                return String(chars)
            } else if lastLower == "đ" {
                // Double tap undo: 'đ' + 'd' -> "dd"
                chars[lastIdx] = lastIsUpper ? "D" : "d"
                chars.append(isUpper ? "D" : "d")
                return String(chars)
            }
            return nil
        }

        // 2. Circumflex: aa -> â, ee -> ê, oo -> ô
        if lowerChar == "a" {
            // Check last char: a -> â
            let baseLast = VietnameseChar.removeTone(lastChar)
            let baseLastLower = Character(baseLast.lowercased())
            let currentTone = VietnameseChar.getTone(lastChar)

            if baseLastLower == "a" {
                let targetBase: Character = lastIsUpper ? "Â" : "â"
                chars[lastIdx] = VietnameseChar.applyTone(targetBase, tone: currentTone)
                return String(chars)
            } else if baseLastLower == "â" {
                // Double tap undo: â + a -> aa
                let targetBase: Character = lastIsUpper ? "A" : "a"
                chars[lastIdx] = VietnameseChar.applyTone(targetBase, tone: currentTone)
                chars.append(isUpper ? "A" : "a")
                return String(chars)
            }
        }

        if lowerChar == "e" {
            let baseLast = VietnameseChar.removeTone(lastChar)
            let baseLastLower = Character(baseLast.lowercased())
            let currentTone = VietnameseChar.getTone(lastChar)

            if baseLastLower == "e" {
                let targetBase: Character = lastIsUpper ? "Ê" : "ê"
                chars[lastIdx] = VietnameseChar.applyTone(targetBase, tone: currentTone)
                return String(chars)
            } else if baseLastLower == "ê" {
                // Double tap undo
                let targetBase: Character = lastIsUpper ? "E" : "e"
                chars[lastIdx] = VietnameseChar.applyTone(targetBase, tone: currentTone)
                chars.append(isUpper ? "E" : "e")
                return String(chars)
            }
        }

        if lowerChar == "o" {
            let baseLast = VietnameseChar.removeTone(lastChar)
            let baseLastLower = Character(baseLast.lowercased())
            let currentTone = VietnameseChar.getTone(lastChar)

            if baseLastLower == "o" {
                let targetBase: Character = lastIsUpper ? "Ô" : "ô"
                chars[lastIdx] = VietnameseChar.applyTone(targetBase, tone: currentTone)
                return String(chars)
            } else if baseLastLower == "ô" {
                // Double tap undo
                let targetBase: Character = lastIsUpper ? "O" : "o"
                chars[lastIdx] = VietnameseChar.applyTone(targetBase, tone: currentTone)
                chars.append(isUpper ? "O" : "o")
                return String(chars)
            }
        }

        // 3. 'w' transformations (Breve & Horn):
        // aw -> ă, ow -> ơ, uw -> ư, uow -> ươ
        if lowerChar == "w" {
            // Check for 'uo' -> 'ươ'
            if chars.count >= 2 {
                let secondLastIdx = chars.count - 2
                let c1 = VietnameseChar.removeTone(chars[secondLastIdx])
                let c2 = VietnameseChar.removeTone(chars[lastIdx])
                let c1Lower = Character(c1.lowercased())
                let c2Lower = Character(c2.lowercased())

                if c1Lower == "u" && c2Lower == "o" {
                    let tone = VietnameseChar.getTone(chars[lastIdx])
                    chars[secondLastIdx] = chars[secondLastIdx].isUppercase ? "Ư" : "ư"
                    let targetO: Character = chars[lastIdx].isUppercase ? "Ơ" : "ơ"
                    chars[lastIdx] = VietnameseChar.applyTone(targetO, tone: tone)
                    return String(chars)
                } else if c1Lower == "ư" && c2Lower == "ơ" {
                    // Undo 'ươ' + 'w' -> 'uow'
                    let tone = VietnameseChar.getTone(chars[lastIdx])
                    chars[secondLastIdx] = chars[secondLastIdx].isUppercase ? "U" : "u"
                    let targetO: Character = chars[lastIdx].isUppercase ? "O" : "o"
                    chars[lastIdx] = VietnameseChar.applyTone(targetO, tone: tone)
                    chars.append(isUpper ? "W" : "w")
                    return String(chars)
                }
            }

            let baseLast = VietnameseChar.removeTone(lastChar)
            let baseLastLower = Character(baseLast.lowercased())
            let currentTone = VietnameseChar.getTone(lastChar)

            if baseLastLower == "a" {
                let targetBase: Character = lastIsUpper ? "Ă" : "ă"
                chars[lastIdx] = VietnameseChar.applyTone(targetBase, tone: currentTone)
                return String(chars)
            } else if baseLastLower == "ă" {
                // Undo ă + w -> aw
                let targetBase: Character = lastIsUpper ? "A" : "a"
                chars[lastIdx] = VietnameseChar.applyTone(targetBase, tone: currentTone)
                chars.append(isUpper ? "W" : "w")
                return String(chars)
            } else if baseLastLower == "o" {
                let targetBase: Character = lastIsUpper ? "Ơ" : "ơ"
                chars[lastIdx] = VietnameseChar.applyTone(targetBase, tone: currentTone)
                return String(chars)
            } else if baseLastLower == "ơ" {
                // Undo ơ + w -> ow
                let targetBase: Character = lastIsUpper ? "O" : "o"
                chars[lastIdx] = VietnameseChar.applyTone(targetBase, tone: currentTone)
                chars.append(isUpper ? "W" : "w")
                return String(chars)
            } else if baseLastLower == "u" {
                let targetBase: Character = lastIsUpper ? "Ư" : "ư"
                chars[lastIdx] = VietnameseChar.applyTone(targetBase, tone: currentTone)
                return String(chars)
            } else if baseLastLower == "ư" {
                // Undo ư + w -> uw
                let targetBase: Character = lastIsUpper ? "U" : "u"
                chars[lastIdx] = VietnameseChar.applyTone(targetBase, tone: currentTone)
                chars.append(isUpper ? "W" : "w")
                return String(chars)
            } else if inputMethod == .telex {
                // Standalone or after a consonant (e.g. "tw" -> "tư")
                chars.append(isUpper ? "Ư" : "ư")
                return String(chars)
            }
        }

        // 4. Bracket shortcuts in Telex: [ -> ơ, ] -> ư, { -> Ơ, } -> Ư
        if inputMethod == .telex || inputMethod == .simpleTelex {
            if char == "[" {
                if lastChar == "ơ" {
                    chars[lastIdx] = "["
                    return String(chars)
                }
                chars.append("ơ")
                return String(chars)
            } else if char == "]" {
                if lastChar == "ư" {
                    chars[lastIdx] = "]"
                    return String(chars)
                }
                chars.append("ư")
                return String(chars)
            } else if char == "{" {
                if lastChar == "Ơ" {
                    chars[lastIdx] = "{"
                    return String(chars)
                }
                chars.append("Ơ")
                return String(chars)
            } else if char == "}" {
                if lastChar == "Ư" {
                    chars[lastIdx] = "}"
                    return String(chars)
                }
                chars.append("Ư")
                return String(chars)
            }
        }

        return nil
    }

    /// Try tone key: s (acute), f (grave), r (hook), x (tilde), j (heavy), z (remove tone)
    public static func tryApplyTone(
        word: String,
        char: Character,
        toneStyle: ToneStyle
    ) -> String? {
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
            // Remove tone and append the raw tone key character
            var cleanWord = ""
            for c in word {
                cleanWord.append(VietnameseChar.removeTone(c))
            }
            cleanWord.append(char)
            return cleanWord
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
                return cleanWord
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

        return String(resultChars)
    }
}

