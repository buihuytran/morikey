import Foundation

public struct SpellingChecker {
    // English consonant clusters that NEVER start a native Vietnamese word
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

    // Consonant clusters that NEVER exist in Vietnamese syllables (initial, medial, or coda)
    public static let invalidClusters: [String] = [
        // R-clusters (never exist before consonant: morning, format, start, word, work, lord, order...)
        "rn", "rm", "rd", "rt", "rk", "rl", "rp", "rb", "rs", "rg",
        // S-clusters (post, test, fast, task, crisp, special...)
        "st", "sh", "sk", "sp", "sc", "sm", "sn", "sl", "sw",
        // L-clusters (cold, result, milk, help...)
        "ld", "lt", "lk", "lp", "lb", "lf", "ls", "lm",
        // N-clusters (point, send, round, client...)
        "nd", "nt", "nk", "ns", "nc",
        // M-clusters (camp, simple...)
        "mp", "mb",
        // Stop clusters (act, script, left, next, check...)
        "ct", "pt", "ft", "xt", "ck", "ts", "ps",
        // Double consonants (never exist in Vietnamese: pass, will, off, middle, button, trigger...)
        "ss", "ll", "ff", "dd", "tt", "bb", "gg", "pp", "cc", "rr", "nn", "mm"
    ]

    public static var invalidFinalClusters: [String] {
        return invalidClusters
    }

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

    /// Checks if a word contains an impossible consonant cluster anywhere inside
    public static func containsInvalidCluster(_ word: String) -> Bool {
        let lower = word.lowercased()
        for cluster in invalidClusters {
            if lower.contains(cluster) {
                return true
            }
        }
        return false
    }

    /// Checks if a word contains multiple syllables (separated by consonants),
    /// which NEVER occurs in native single Vietnamese words (e.g. "morning", "system", "format", "number").
    public static func isPolysyllabicWord(_ word: String) -> Bool {
        let lower = word.lowercased()
        guard lower.count >= 3 else { return false }

        var vowelGroupCount = 0
        var inVowelGroup = false

        for c in lower {
            if VietnameseChar.isVowel(c) {
                if !inVowelGroup {
                    inVowelGroup = true
                    vowelGroupCount += 1
                }
            } else {
                inVowelGroup = false
            }
        }

        return vowelGroupCount >= 2
    }

    /// Checks if a word in buffer is definitively non-Vietnamese (English)
    public static func isNonVietnameseWord(_ word: String) -> Bool {
        let lower = word.lowercased()
        guard !lower.isEmpty else { return false }

        if hasInvalidInitialCluster(lower) {
            return true
        }
        if hasForeignInitialOrChar(lower) {
            return true
        }
        if containsInvalidCluster(lower) {
            return true
        }
        if isPolysyllabicWord(lower) {
            return true
        }
        if EnglishDictionary.isCommonEnglishWord(lower) {
            return true
        }
        return false
    }

    /// Checks if a word ends in a consonant or cluster that cannot exist in Vietnamese
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

        // Check invalid clusters (morning -> "rn", format -> "rm", post -> "st", text -> "xt"...)
        for cluster in invalidClusters {
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

    /// Common, native Vietnamese words that must NEVER be restored to English
    private static let protectedVietnameseWords: Set<String> = [
        "ít", "cả", "cơ", "bơ", "tơ", "lơ", "mã", "sĩ", "bả", "há", "hí", "hát",
        "toán", "toản", "chúc", "tiếp", "đường", "buổi", "sáng", "mừng", "việt", "tiếng",
        "ơn", "cơn", "sơn", "hơn", "đơn", "rơm"
    ]

    public static func isProtectedVietnameseWord(_ word: String) -> Bool {
        return protectedVietnameseWords.contains(word.lowercased())
    }

    /// Determines if a completed word (or raw keystroke sequence) is an English word
    public static func isLikelyEnglishWord(currentWord: String, rawWord: String) -> Bool {
        let cleanRaw = rawWord.lowercased()
        let cleanCurrent = currentWord.lowercased()

        // If the current word is an explicit, native Vietnamese word (like "ít", "cả", "toán"...),
        // NEVER restore it to English!
        if isProtectedVietnameseWord(cleanCurrent) {
            return false
        }

        // 1. Direct match with English dictionary words (is, as, us, if, of, or, this, see, good, look, morning...)
        if EnglishDictionary.isCommonEnglishWord(cleanRaw) {
            return true
        }

        // 2. Polysyllabic structure (morning, system, server, number, format, window, docker...)
        if isPolysyllabicWord(cleanCurrent) {
            return true
        }

        // 3. Starts with non-Vietnamese initial cluster (class, clear, free, print, start, scale...)
        if hasInvalidInitialCluster(cleanRaw) {
            return true
        }

        // 4. Starts with foreign letters (f, j, z)
        if hasForeignInitialOrChar(cleanRaw) || hasForeignInitialOrChar(cleanCurrent) {
            return true
        }

        // 5. Transformed word ends with non-Vietnamese coda (gôd -> 'd', lôk -> 'k', fêl -> 'l', clẻar -> 'r')
        if hasInvalidCoda(cleanCurrent) {
            return true
        }

        return false
    }
}
