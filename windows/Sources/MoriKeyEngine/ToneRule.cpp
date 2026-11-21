#include "ToneRule.h"
#include "VietnameseChar.h"
#include <vector>
#include <algorithm>
#include <cwctype>

static std::wstring toLowerStr(const std::wstring& str) {
    std::wstring lower = str;
    for (auto& c : lower) {
        c = static_cast<wchar_t>(std::towlower(c));
    }
    return lower;
}

std::optional<size_t> ToneRule::findToneTargetIndex(const std::wstring& word, ToneStyle toneStyle) {
    if (word.empty()) return std::nullopt;

    std::vector<size_t> vowelIndices;
    for (size_t i = 0; i < word.length(); ++i) {
        if (VietnameseChar::isVowel(word[i])) {
            vowelIndices.push_back(i);
        }
    }

    if (vowelIndices.empty()) return std::nullopt;
    if (vowelIndices.size() == 1) {
        return vowelIndices[0];
    }

    // Special handling for initial "qu" and "gi"
    std::vector<size_t> adjustedVowelIndices = vowelIndices;
    std::wstring lowerWord = toLowerStr(word);

    if (lowerWord.rfind(L"qu", 0) == 0 && adjustedVowelIndices.size() > 1 && adjustedVowelIndices[0] == 1) {
        adjustedVowelIndices.erase(adjustedVowelIndices.begin());
    } else if (lowerWord.rfind(L"gi", 0) == 0 && adjustedVowelIndices.size() > 1 && adjustedVowelIndices[0] == 1) {
        adjustedVowelIndices.erase(adjustedVowelIndices.begin());
    }

    if (adjustedVowelIndices.size() == 1) {
        return adjustedVowelIndices[0];
    }

    // Check if there is a final consonant after the last vowel
    size_t lastVowelIndex = adjustedVowelIndices.back();
    bool hasFinalConsonant = (lastVowelIndex < word.length() - 1);

    // Rule: If one vowel has a circumflex/horn (â, ê, ô, ơ, ư, ă), it takes priority
    static const std::unordered_set<wchar_t> diacriticVowels = {
        L'â', L'ê', L'ô', L'ơ', L'ư', L'ă',
        L'Â', L'Ê', L'Ô', L'Ơ', L'Ư', L'Ă'
    };

    for (size_t idx : adjustedVowelIndices) {
        wchar_t base = VietnameseChar::removeTone(word[idx]);
        if (diacriticVowels.find(base) != diacriticVowels.end()) {
            // If both 'u' and 'ơ' have horn (e.g., "ươ"), tone goes on 'ơ'
            size_t nextIdx = idx + 1;
            if (nextIdx < word.length()) {
                wchar_t nextBase = VietnameseChar::removeTone(word[nextIdx]);
                if ((base == L'ư' || base == L'Ư') && (nextBase == L'ơ' || nextBase == L'Ơ')) {
                    return nextIdx;
                }
            }
            return idx;
        }
    }

    // If 2 vowels:
    if (adjustedVowelIndices.size() == 2) {
        size_t firstIdx = adjustedVowelIndices[0];
        size_t secondIdx = adjustedVowelIndices[1];
        std::wstring pair = { static_cast<wchar_t>(std::towlower(word[firstIdx])),
                              static_cast<wchar_t>(std::towlower(word[secondIdx])) };

        if (hasFinalConsonant) {
            // With final consonant, always on second vowel (e.g. toán, hoàn, biến)
            return secondIdx;
        } else {
            // Without final consonant
            if (pair == L"oa" || pair == L"oe" || pair == L"uy") {
                switch (toneStyle) {
                case ToneStyle::Modern:
                    return firstIdx;  // hòa, thúy, khỏe
                case ToneStyle::Classic:
                    return secondIdx; // hoà, thuý, khoẻ
                }
            } else {
                // For ia, ie, ua, uo -> first vowel (tía, múa, mía)
                return firstIdx;
            }
        }
    }

    // If 3 vowels (e.g. ngoai, khoai, khuyu):
    if (adjustedVowelIndices.size() >= 3) {
        // Usually the middle vowel (khoái, ngoài, khuỷu)
        return adjustedVowelIndices[1];
    }

    return adjustedVowelIndices[0];
}

std::wstring ToneRule::repositionTone(const std::wstring& word, ToneStyle toneStyle) {
    Tone currentTone = Tone::None;
    for (wchar_t c : word) {
        Tone t = VietnameseChar::getTone(c);
        if (t != Tone::None) {
            currentTone = t;
            break;
        }
    }
    if (currentTone == Tone::None) return word;

    std::wstring cleanWord;
    cleanWord.reserve(word.length());
    for (wchar_t c : word) {
        cleanWord.push_back(VietnameseChar::removeTone(c));
    }

    auto targetIndex = findToneTargetIndex(cleanWord, toneStyle);
    if (!targetIndex.has_value()) {
        return word;
    }

    std::wstring result = cleanWord;
    size_t idx = targetIndex.value();
    result[idx] = VietnameseChar::applyTone(result[idx], currentTone);
    return result;
}

