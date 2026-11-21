#include "SpellingChecker.h"
#include "VietnameseChar.h"
#include "EnglishDictionary.h"
#include <cwctype>
#include <algorithm>

static std::wstring toLowerStr(const std::wstring& str) {
    std::wstring lower = str;
    for (auto& c : lower) {
        c = static_cast<wchar_t>(std::towlower(c));
    }
    return lower;
}

static bool strHasPrefix(const std::wstring& str, const std::wstring& prefix) {
    if (str.length() < prefix.length()) return false;
    return str.compare(0, prefix.length(), prefix) == 0;
}

static bool strHasSuffix(const std::wstring& str, const std::wstring& suffix) {
    if (str.length() < suffix.length()) return false;
    return str.compare(str.length() - suffix.length(), suffix.length(), suffix) == 0;
}

static const std::vector<std::wstring> s_invalidInitialClusters = {
    L"str", L"sch", L"scr", L"spl", L"spr",
    L"bl", L"br", L"cl", L"cr", L"dr", L"fl", L"fr", L"gl", L"gr",
    L"pl", L"pr", L"sc", L"sk", L"sl", L"sm", L"sn", L"sp", L"st",
    L"sw", L"wh", L"wr"
};

static const std::unordered_set<wchar_t> s_invalidSingleCodas = {
    L'b', L'd', L'đ', L'f', L'j', L'k', L'l', L'q', L'r', L's', L'v', L'w', L'x', L'z'
};

static const std::vector<std::wstring> s_invalidClusters = {
    // R-clusters
    L"rn", L"rm", L"rd", L"rt", L"rk", L"rl", L"rp", L"rb", L"rs", L"rg",
    // S-clusters
    L"st", L"sh", L"sk", L"sp", L"sc", L"sm", L"sn", L"sl", L"sw",
    // L-clusters
    L"ld", L"lt", L"lk", L"lp", L"lb", L"lf", L"ls", L"lm",
    // N-clusters
    L"nd", L"nt", L"nk", L"ns", L"nc",
    // M-clusters
    L"mp", L"mb",
    // Stop clusters
    L"ct", L"pt", L"ft", L"xt", L"ck", L"ts", L"ps",
    // Double consonants
    L"ss", L"ll", L"ff", L"dd", L"tt", L"bb", L"gg", L"pp", L"cc", L"rr", L"nn", L"mm"
};

static const std::unordered_set<std::wstring> s_protectedVietnameseWords = {
    L"ít", L"cả", L"cơ", L"bơ", L"tơ", L"lơ", L"mã", L"sĩ", L"bả", L"há", L"hí", L"hát",
    L"toán", L"toản", L"chúc", L"tiếp", L"đường", L"buổi", L"sáng", L"mừng", L"việt", L"tiếng"
};

const std::vector<std::wstring>& SpellingChecker::getInvalidClusters() {
    return s_invalidClusters;
}

bool SpellingChecker::hasInvalidInitialCluster(const std::wstring& word) {
    std::wstring lower = toLowerStr(word);
    for (const auto& cluster : s_invalidInitialClusters) {
        if (strHasPrefix(lower, cluster)) {
            return true;
        }
    }
    return false;
}

bool SpellingChecker::hasForeignInitialOrChar(const std::wstring& word) {
    std::wstring lower = toLowerStr(word);
    if (!lower.empty()) {
        wchar_t first = lower[0];
        if (first == L'f' || first == L'j' || first == L'z') {
            return true;
        }
    }
    return false;
}

bool SpellingChecker::containsInvalidCluster(const std::wstring& word) {
    std::wstring lower = toLowerStr(word);
    for (const auto& cluster : s_invalidClusters) {
        if (lower.find(cluster) != std::wstring::npos) {
            return true;
        }
    }
    return false;
}

bool SpellingChecker::isPolysyllabicWord(const std::wstring& word) {
    std::wstring lower = toLowerStr(word);
    if (lower.length() < 3) return false;

    int vowelGroupCount = 0;
    bool inVowelGroup = false;

    for (wchar_t c : lower) {
        if (VietnameseChar::isVowel(c)) {
            if (!inVowelGroup) {
                inVowelGroup = true;
                vowelGroupCount++;
            }
        } else {
            inVowelGroup = false;
        }
    }

    return vowelGroupCount >= 2;
}

bool SpellingChecker::isNonVietnameseWord(const std::wstring& word) {
    std::wstring lower = toLowerStr(word);
    if (lower.empty()) return false;

    if (hasInvalidInitialCluster(lower)) return true;
    if (hasForeignInitialOrChar(lower)) return true;
    if (containsInvalidCluster(lower)) return true;
    if (isPolysyllabicWord(lower)) return true;
    if (EnglishDictionary::isCommonEnglishWord(lower)) return true;

    return false;
}

bool SpellingChecker::hasInvalidCoda(const std::wstring& word) {
    std::wstring lower = toLowerStr(word);
    if (lower.empty()) return false;

    bool hasVowel = false;
    for (wchar_t c : lower) {
        if (VietnameseChar::isVowel(c)) {
            hasVowel = true;
            break;
        }
    }
    if (!hasVowel) return false;

    // Check invalid clusters
    for (const auto& cluster : s_invalidClusters) {
        if (strHasSuffix(lower, cluster)) {
            return true;
        }
    }

    // Check invalid single coda
    wchar_t last = lower.back();
    wchar_t baseLast = VietnameseChar::removeTone(last);
    if (s_invalidSingleCodas.find(baseLast) != s_invalidSingleCodas.end()) {
        return true;
    }

    // 'g' can only end a word as part of 'ng' (tiếng, đường, sang)
    if (baseLast == L'g' && !strHasSuffix(lower, L"ng")) {
        return true;
    }

    // 'h' can only end a word as part of 'ch' or 'nh' (thích, anh, mình)
    if (baseLast == L'h' && !strHasSuffix(lower, L"ch") && !strHasSuffix(lower, L"nh")) {
        return true;
    }

    return false;
}

bool SpellingChecker::isValidVietnameseSyllable(const std::wstring& word) {
    std::wstring lower = toLowerStr(word);
    if (lower.empty()) return true;

    if (hasInvalidInitialCluster(lower)) return false;
    if (hasForeignInitialOrChar(lower)) return false;
    if (hasInvalidCoda(lower)) return false;

    return true;
}

bool SpellingChecker::isProtectedVietnameseWord(const std::wstring& word) {
    return s_protectedVietnameseWords.find(toLowerStr(word)) != s_protectedVietnameseWords.end();
}

bool SpellingChecker::isLikelyEnglishWord(const std::wstring& currentWord, const std::wstring& rawWord) {
    std::wstring cleanRaw = toLowerStr(rawWord);
    std::wstring cleanCurrent = toLowerStr(currentWord);

    if (isProtectedVietnameseWord(cleanCurrent)) {
        return false;
    }

    if (EnglishDictionary::isCommonEnglishWord(cleanRaw)) {
        return true;
    }

    if (isPolysyllabicWord(cleanCurrent)) {
        return true;
    }

    if (hasInvalidInitialCluster(cleanRaw)) {
        return true;
    }

    if (hasForeignInitialOrChar(cleanRaw) || hasForeignInitialOrChar(cleanCurrent)) {
        return true;
    }

    if (hasInvalidCoda(cleanCurrent)) {
        return true;
    }

    return false;
}

