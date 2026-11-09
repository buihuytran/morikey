import Foundation

public struct VIQRTransform {
    public static func tryTransformVIQR(
        word: String,
        char: Character,
        toneStyle: ToneStyle
    ) -> String? {
        var chars = Array(word)
        guard !chars.isEmpty else { return nil }

        let lastIdx = chars.count - 1
        let lastChar = chars[lastIdx]
        let lastLower = Character(lastChar.lowercased())
        let lastIsUpper = lastChar.isUppercase

        // 1. Circumflex (^): a^ -> â, e^ -> ê, o^ -> ô
        if char == "^" {
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
                    chars[i] = VietnameseChar.applyTone(isUp ? "A" : "a", tone: tone)
                    chars.append("^")
                    return String(chars)
                } else if baseLower == "ê" {
                    chars[i] = VietnameseChar.applyTone(isUp ? "E" : "e", tone: tone)
                    chars.append("^")
                    return String(chars)
                } else if baseLower == "ô" {
                    chars[i] = VietnameseChar.applyTone(isUp ? "O" : "o", tone: tone)
                    chars.append("^")
                    return String(chars)
                }
            }
            return nil
        }

        // 2. Horn (+ or *): o+ -> ơ, u+ -> ư, uo+ -> ươ
        if char == "+" || char == "*" {
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
                    let tone = VietnameseChar.getTone(chars[lastIdx])
                    chars[sIdx] = chars[sIdx].isUppercase ? "U" : "u"
                    chars[lastIdx] = VietnameseChar.applyTone(chars[lastIdx].isUppercase ? "O" : "o", tone: tone)
                    chars.append(char)
                    return String(chars)
                }
            }

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
                    chars.append(char)
                    return String(chars)
                } else if baseLower == "ơ" {
                    chars[i] = VietnameseChar.applyTone(isUp ? "O" : "o", tone: tone)
                    chars.append(char)
                    return String(chars)
                }
            }
            return nil
        }

        // 3. Breve ((): a( -> ă
        if char == "(" {
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
                    chars.append("(")
                    return String(chars)
                }
            }
            return nil
        }

        // 4. Crossed (- or d): d- -> đ, dd -> đ
        if char == "-" {
            if lastLower == "d" {
                chars[lastIdx] = lastIsUpper ? "Đ" : "đ"
                return String(chars)
            } else if lastLower == "đ" {
                chars[lastIdx] = lastIsUpper ? "D" : "d"
                chars.append("-")
                return String(chars)
            }
            return nil
        }

        if char.lowercased() == "d" && lastLower == "d" {
            chars[lastIdx] = lastIsUpper ? "Đ" : "đ"
            return String(chars)
        }

        // 5. Tones: ' (sắc), ` (huyền), ? (hỏi), ~ (ngã), . (nặng), 0 (xóa)
        let tone: Tone?
        switch char {
        case "'": tone = .acute
        case "`": tone = .grave
        case "?": tone = .hook
        case "~": tone = .tilde
        case ".": tone = .heavy
        case "0": tone = Tone.none
        default:  tone = nil
        }

        guard let targetTone = tone else { return nil }

        // Find existing tone
        var currentTone: Tone = .none
        for c in word {
            let t = VietnameseChar.getTone(c)
            if t != .none {
                currentTone = t
                break
            }
        }

        // Double tap: toggle off and append raw character
        if targetTone != .none && currentTone == targetTone {
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

        if targetTone == .none {
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
        resultChars[offset] = VietnameseChar.applyTone(resultChars[offset], tone: targetTone)
        return String(resultChars)
    }
}
