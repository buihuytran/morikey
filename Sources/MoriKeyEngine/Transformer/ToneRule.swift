import Foundation

public struct ToneRule {
    /// Determines the best index in `word` (among vowels) to place the tone
    public static func findToneTargetIndex(in word: String, toneStyle: ToneStyle) -> String.Index? {
        let chars = Array(word)
        guard !chars.isEmpty else { return nil }

        // Find all vowel indices
        var vowelIndices: [Int] = []
        for i in 0..<chars.count {
            if VietnameseChar.isVowel(chars[i]) {
                vowelIndices.append(i)
            }
        }

        guard !vowelIndices.isEmpty else { return nil }
        if vowelIndices.count == 1 {
            return word.index(word.startIndex, offsetBy: vowelIndices[0])
        }

        // Special handling for initial "qu" and "gi"
        // In "qu", 'u' behaves as part of consonant cluster if followed by another vowel
        // In "gi", 'i' behaves as part of consonant cluster if followed by another vowel
        var adjustedVowelIndices = vowelIndices
        let lowerWord = word.lowercased()

        if lowerWord.hasPrefix("qu") && adjustedVowelIndices.count > 1 && adjustedVowelIndices.first == 1 {
            adjustedVowelIndices.removeFirst()
        } else if lowerWord.hasPrefix("gi") && adjustedVowelIndices.count > 1 && adjustedVowelIndices.first == 1 {
            adjustedVowelIndices.removeFirst()
        }

        if adjustedVowelIndices.count == 1 {
            return word.index(word.startIndex, offsetBy: adjustedVowelIndices[0])
        }

        // Check if there is a final consonant after the last vowel
        let lastVowelIndex = adjustedVowelIndices.last!
        let hasFinalConsonant = (lastVowelIndex < chars.count - 1)

        // Rule: If one vowel has a circumflex/horn (â, ê, ô, ơ, ư, ă), it takes priority
        let diacriticVowels: Set<Character> = [
            "â", "ê", "ô", "ơ", "ư", "ă",
            "Â", "Ê", "Ô", "Ơ", "Ư", "Ă"
        ]

        // Check if any vowel has diacritic
        for idx in adjustedVowelIndices {
            let base = VietnameseChar.removeTone(chars[idx])
            if diacriticVowels.contains(base) {
                // If both 'u' and 'ơ' have horn (e.g., "ươ"), tone goes on 'ơ'
                let nextIdx = idx + 1
                if nextIdx < chars.count {
                    let nextBase = VietnameseChar.removeTone(chars[nextIdx])
                    if (base == "ư" || base == "Ư") && (nextBase == "ơ" || nextBase == "Ơ") {
                        return word.index(word.startIndex, offsetBy: nextIdx)
                    }
                }
                return word.index(word.startIndex, offsetBy: idx)
            }
        }

        // If 2 vowels:
        if adjustedVowelIndices.count == 2 {
            let firstIdx = adjustedVowelIndices[0]
            let secondIdx = adjustedVowelIndices[1]
            let pair = "\(chars[firstIdx])\(chars[secondIdx])".lowercased()

            if hasFinalConsonant {
                // With final consonant, always on second vowel (e.g. toán, hoàn, biến)
                return word.index(word.startIndex, offsetBy: secondIdx)
            } else {
                // Without final consonant
                if pair == "oa" || pair == "oe" || pair == "uy" {
                    switch toneStyle {
                    case .modern:
                        return word.index(word.startIndex, offsetBy: firstIdx)  // hòa, thúy, khỏe
                    case .classic:
                        return word.index(word.startIndex, offsetBy: secondIdx) // hoà, thuý, khoẻ
                    }
                } else {
                    // For ia, ie, ua, uo -> first vowel (tía, múa, mía)
                    return word.index(word.startIndex, offsetBy: firstIdx)
                }
            }
        }

        // If 3 vowels (e.g. ngoai, khoai, khuyu):
        if adjustedVowelIndices.count >= 3 {
            // Usually the middle vowel (khoái, ngoài, khuỷu)
            let midIdx = adjustedVowelIndices[1]
            return word.index(word.startIndex, offsetBy: midIdx)
        }

        return word.index(word.startIndex, offsetBy: adjustedVowelIndices[0])
    }
}

