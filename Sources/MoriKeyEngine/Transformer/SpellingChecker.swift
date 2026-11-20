import Foundation

public struct SpellingChecker {
    // English consonant clusters that NEVER start a native Vietnamese word
    // Note: 'tw' is excluded because in Telex 'tw' represents 'tư'; 'tr' is excluded because it's native Vietnamese.
    private static let invalidInitialClusters: [String] = [
        "str", "sch", "scr", "spl", "spr",
        "bl", "br", "cl", "cr", "dr", "fl", "fr", "gl", "gr",
        "pl", "pr", "sc", "sk", "sl", "sm", "sn", "sp", "st",
        "sw", "wh", "wr"
    ]

    // Consonants that can NEVER end a Vietnamese syllable
    // Valid codas in native Vietnamese: c, ch, m, n, ng, nh, p, t (or vowel/open syllable)
    private static let invalidSingleCodas: Set<Character> = [
        "b", "d", "đ", "f", "j", "k", "l", "q", "r", "s", "v", "w", "x", "z"
    ]

    // Final consonant clusters that NEVER exist in Vietnamese syllables
    public static let invalidFinalClusters: [String] = [
        "st", "sh", "rt", "xt", "ck", "ct", "ft", "lt", "sp", "sk",
        "mp", "nd", "nt", "rd", "ld", "rk", "lk", "ts", "ps", "pt",
        "ss", "ll", "ff", "dd", "tt", "bb", "gg", "mb", "gh", "ph", "th"
    ]

    /// Checks if a word starts with an English-only consonant cluster (e.g. "cl", "fr", "st", "sp", "pr")
    public static func hasInvalidInitialCluster(_ word: String) -> Bool {
        let lower = word.lowercased()
        for cluster in invalidInitialClusters {
            if lower.hasPrefix(cluster) {
                return true
            }
        }
        return false
    }

    /// Checks if a word starts with a foreign letter (f, j, z) that cannot start any Vietnamese word
    public static func hasForeignInitialOrChar(_ word: String) -> Bool {
        let lower = word.lowercased()
        if let first = lower.first, first == "f" || first == "j" || first == "z" {
            return true
        }
        return false
    }

    /// Checks if a word ends in a consonant or cluster that cannot exist in Vietnamese
    /// (Should be evaluated on currentWord, not rawWord which contains Telex tone keys like 's', 'f', 'r', 'x', 'j')
    public static func hasInvalidCoda(_ word: String) -> Bool {
        let lower = word.lowercased()
        guard !lower.isEmpty else { return false }

        // Must have at least one vowel before checking coda
        var hasVowel = false
        for c in lower {
            if VietnameseChar.isVowel(c) {
                hasVowel = true
                break
            }
        }
        guard hasVowel else { return false }

        // Check invalid clusters (post, text, fish, card, cold, test, help...)
        for cluster in invalidFinalClusters {
            if lower.hasSuffix(cluster) {
                return true
            }
        }

        // Check invalid single coda (good -> 'd', look -> 'k', feel -> 'l', clear -> 'r')
        if let last = lower.last {
            let baseLast = VietnameseChar.removeTone(last)
            if invalidSingleCodas.contains(baseLast) {
                return true
            }

            // 'g' can only end a word as part of 'ng' (tiếng, đường, sang)
            if baseLast == "g" && !lower.hasSuffix("ng") {
                return true
            }

            // 'h' can only end a word as part of 'ch' or 'nh' (thích, anh, mình)
            if baseLast == "h" && !lower.hasSuffix("ch") && !lower.hasSuffix("nh") {
                return true
            }
        }

        return false
    }

    /// Checks if a syllable structure is valid in Vietnamese phonology
    public static func isValidVietnameseSyllable(_ word: String) -> Bool {
        let lower = word.lowercased()
        guard !lower.isEmpty else { return true }

        if hasInvalidInitialCluster(lower) {
            return false
        }

        if hasForeignInitialOrChar(lower) {
            return false
        }

        if hasInvalidCoda(lower) {
            return false
        }

        return true
    }

    /// Determines if a completed word (or raw keystroke sequence) is an English word
    public static func isLikelyEnglishWord(currentWord: String, rawWord: String) -> Bool {
        let cleanRaw = rawWord.lowercased()
        let cleanCurrent = currentWord.lowercased()

        // 1. Direct match with English dictionary words (is, as, us, if, of, or, this, see, good, look, const, return, system, server...)
        if EnglishDictionary.isCommonEnglishWord(cleanRaw) {
            return true
        }

        // 2. Starts with non-Vietnamese initial cluster (class, clear, free, print, start, scale...)
        if hasInvalidInitialCluster(cleanRaw) {
            return true
        }

        // 3. Starts with foreign letters (f, j, z)
        if hasForeignInitialOrChar(cleanRaw) || hasForeignInitialOrChar(cleanCurrent) {
            return true
        }

        // 4. Raw word ends with English final cluster (post, test, text, help, card, desk...)
        for cluster in invalidFinalClusters {
            if cleanRaw.hasSuffix(cluster) {
                return true
            }
        }

        // 5. Transformed word ends with non-Vietnamese coda (gôd -> 'd', lôk -> 'k', fêl -> 'l', clẻar -> 'r')
        if hasInvalidCoda(cleanCurrent) {
            return true
        }

        return false
    }
}
