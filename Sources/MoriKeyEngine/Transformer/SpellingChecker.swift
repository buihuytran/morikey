import Foundation

public struct SpellingChecker {
    // Valid final consonants in Vietnamese: c, ch, m, n, ng, nh, p, t
    // (or open syllables ending in vowels)
    private static let validCodas: Set<String> = [
        "c", "ch", "m", "n", "ng", "nh", "p", "t"
    ]

    private static let invalidClusters: [String] = [
        "st", "sh", "rt", "xt", "ck", "ct", "ft", "sp", "sk", "mp", "nd", "rd", "ld", "rk", "lk", "ts", "ps"
    ]

    /// Checks if a syllable structure is valid in Vietnamese phonology
    public static func isValidVietnameseSyllable(_ word: String) -> Bool {
        let lower = word.lowercased()
        guard !lower.isEmpty else { return true }

        // Reject invalid consonant clusters (post, fast, test, shift, text...)
        for cluster in invalidClusters {
            if lower.hasSuffix(cluster) {
                return false
            }
        }

        // Rule for stop consonants (c, ch, p, t): only Acute (Sắc) or Heavy (Nặng) tones allowed
        let stopCodas = ["c", "ch", "p", "t"]
        for stop in stopCodas {
            if lower.hasSuffix(stop) {
                for char in lower {
                    let tone = VietnameseChar.getTone(char)
                    if tone == .grave || tone == .hook || tone == .tilde {
                        return false // E.g. "màc", "bảt", "thĩp" are invalid
                    }
                }
            }
        }

        return true
    }
}
