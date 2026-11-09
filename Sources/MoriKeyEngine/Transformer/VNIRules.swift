import Foundation

public struct VNITransform {
    public static func tryTransformVNI(
        word: String,
        char: Character,
        toneStyle: ToneStyle
    ) -> String? {
        guard char.isNumber else { return nil }
        var chars = Array(word)
        guard !chars.isEmpty else { return nil }

        let lastIdx = chars.count - 1
        let lastChar = chars[lastIdx]
        let lastLower = Character(lastChar.lowercased())
        let lastIsUpper = lastChar.isUppercase

        switch char {
        // 9: Đ / đ
        case "9":
            if lastLower == "d" {
                chars[lastIdx] = lastIsUpper ? "Đ" : "đ"
                return String(chars)
            } else if lastLower == "đ" {
                // Double tap 9: đ + 9 -> d9
                chars[lastIdx] = lastIsUpper ? "D" : "d"
                chars.append("9")
                return String(chars)
            }
            return nil

        // 6: Â, Ê, Ô (Circumflex)
        case "6":
            // Find last vowel that can take circumflex: a, e, o
            for i in stride(from: chars.count - 1, through: 0, by: -1) {
                let base = VietnameseChar.removeTone(chars[i])
                let baseLower = Character(base.lowercased())
                let isUp = chars[i].isUppercase
                let tone = VietnameseChar.getTone(chars[i])

                if baseLower == "a" {
                    chars[i] = VietnameseChar.applyTone(isUp ? "Â" : "â", tone: tone)
                    return String(chars)
                } else if baseLower == "e" {
                    chars[i] = VietnameseChar.applyTone(isUp ? "Ê" : "ê", tone: tone)
                    return String(chars)
                } else if baseLower == "o" {
                    chars[i] = VietnameseChar.applyTone(isUp ? "Ô" : "ô", tone: tone)
                    return String(chars)
                } else if baseLower == "â" {
                    // Undo
                    chars[i] = VietnameseChar.applyTone(isUp ? "A" : "a", tone: tone)
                    chars.append("6")
                    return String(chars)
                } else if baseLower == "ê" {
                    chars[i] = VietnameseChar.applyTone(isUp ? "E" : "e", tone: tone)
                    chars.append("6")
                    return String(chars)
                } else if baseLower == "ô" {
                    chars[i] = VietnameseChar.applyTone(isUp ? "O" : "o", tone: tone)
                    chars.append("6")
                    return String(chars)
                }
            }
            return nil

        // 7: Ơ, Ư (Horn)
        case "7":
            // Check for 'uo' -> 'ươ'
            if chars.count >= 2 {
                let sIdx = chars.count - 2
                let c1 = VietnameseChar.removeTone(chars[sIdx])
                let c2 = VietnameseChar.removeTone(chars[lastIdx])
                let c1Lower = Character(c1.lowercased())
                let c2Lower = Character(c2.lowercased())

                if c1Lower == "u" && c2Lower == "o" {
                    let tone = VietnameseChar.getTone(chars[lastIdx])
                    chars[sIdx] = chars[sIdx].isUppercase ? "Ư" : "ư"
                    chars[lastIdx] = VietnameseChar.applyTone(chars[lastIdx].isUppercase ? "Ơ" : "ơ", tone: tone)
                    return String(chars)
                } else if c1Lower == "ư" && c2Lower == "ơ" {
                    // Undo
                    let tone = VietnameseChar.getTone(chars[lastIdx])
                    chars[sIdx] = chars[sIdx].isUppercase ? "U" : "u"
                    chars[lastIdx] = VietnameseChar.applyTone(chars[lastIdx].isUppercase ? "O" : "o", tone: tone)
                    chars.append("7")
                    return String(chars)
                }
            }

            // Single u -> ư, o -> ơ
            for i in stride(from: chars.count - 1, through: 0, by: -1) {
                let base = VietnameseChar.removeTone(chars[i])
                let baseLower = Character(base.lowercased())
                let isUp = chars[i].isUppercase
                let tone = VietnameseChar.getTone(chars[i])

                if baseLower == "u" {
                    chars[i] = VietnameseChar.applyTone(isUp ? "Ư" : "ư", tone: tone)
                    return String(chars)
                } else if baseLower == "o" {
                    chars[i] = VietnameseChar.applyTone(isUp ? "Ơ" : "ơ", tone: tone)
                    return String(chars)
                } else if baseLower == "ư" {
                    chars[i] = VietnameseChar.applyTone(isUp ? "U" : "u", tone: tone)
                    chars.append("7")
                    return String(chars)
                } else if baseLower == "ơ" {
                    chars[i] = VietnameseChar.applyTone(isUp ? "O" : "o", tone: tone)
                    chars.append("7")
                    return String(chars)
                }
            }
            return nil

        // 8: Ă (Breve)
        case "8":
            for i in stride(from: chars.count - 1, through: 0, by: -1) {
                let base = VietnameseChar.removeTone(chars[i])
                let baseLower = Character(base.lowercased())
                let isUp = chars[i].isUppercase
                let tone = VietnameseChar.getTone(chars[i])

                if baseLower == "a" {
                    chars[i] = VietnameseChar.applyTone(isUp ? "Ă" : "ă", tone: tone)
                    return String(chars)
                } else if baseLower == "ă" {
                    chars[i] = VietnameseChar.applyTone(isUp ? "A" : "a", tone: tone)
                    chars.append("8")
                    return String(chars)
                }
            }
            return nil

        // 1..5, 0: Tones
        case "1", "2", "3", "4", "5", "0":
            let tone: Tone
            switch char {
            case "1": tone = .acute
            case "2": tone = .grave
            case "3": tone = .hook
            case "4": tone = .tilde
            case "5": tone = .heavy
            default:  tone = .none
            }

            // Find existing tone
            var currentTone: Tone = .none
            for c in word {
                let t = VietnameseChar.getTone(c)
                if t != .none {
                    currentTone = t
                    break
                }
            }

            // Double tap same tone key: restore number
            if tone != .none && currentTone == tone {
                var cleanWord = ""
                for c in word {
                    cleanWord.append(VietnameseChar.removeTone(c))
                }
                cleanWord.append(char)
                return cleanWord
            }

            var baseWordChars: [Character] = []
            for c in word {
                baseWordChars.append(VietnameseChar.removeTone(c))
            }
            let cleanWord = String(baseWordChars)

            if tone == .none {
                if currentTone != .none {
                    return cleanWord
                }
                return nil
            }

            guard let targetIndex = ToneRule.findToneTargetIndex(in: cleanWord, toneStyle: toneStyle) else {
                return nil
            }

            var resultChars = Array(cleanWord)
            let offset = cleanWord.distance(from: cleanWord.startIndex, to: targetIndex)
            resultChars[offset] = VietnameseChar.applyTone(resultChars[offset], tone: tone)
            return String(resultChars)

        default:
            return nil
        }
    }
}

