#include "DiacriticTransform.h"
#include "VietnameseChar.h"
#include "ToneRule.h"
#include <cwctype>
#include <unordered_set>

static std::wstring toLowerStr(const std::wstring& str) {
    std::wstring lower = str;
    for (auto& c : lower) {
        c = static_cast<wchar_t>(std::towlower(c));
    }
    return lower;
}

std::optional<TransformResult> DiacriticTransform::tryTransformVowel(
    const std::wstring& word,
    const std::wstring& rawWord,
    wchar_t ch,
    InputMethod inputMethod,
    bool wAtWordStartAsW
) {
    bool isUpper = std::iswupper(ch);
    wchar_t lowerChar = static_cast<wchar_t>(std::towlower(ch));
    std::wstring chars = word;

    // Empty buffer: user is typing the FIRST character of the word
    if (chars.empty()) {
        if (lowerChar == L'w') {
            if (wAtWordStartAsW || inputMethod == InputMethod::SimpleTelex) {
                return std::nullopt;
            } else if (inputMethod == InputMethod::Telex) {
                return TransformResult(isUpper ? L"Ư" : L"ư", false);
            }
        }

        if (inputMethod == InputMethod::Telex || inputMethod == InputMethod::SimpleTelex) {
            if (ch == L'[') return TransformResult(L"ơ", false);
            if (ch == L']') return TransformResult(L"ư", false);
            if (ch == L'{') return TransformResult(L"Ơ", false);
            if (ch == L'}') return TransformResult(L"Ư", false);
        }
        return std::nullopt;
    }

    size_t lastIdx = chars.length() - 1;
    wchar_t lastChar = chars[lastIdx];
    wchar_t lastLower = static_cast<wchar_t>(std::towlower(lastChar));
    bool lastIsUpper = std::iswupper(lastChar);

    // 1. "dd" or "dD" -> "đ" / "Đ"
    if (lowerChar == L'd') {
        if (lastLower == L'd') {
            chars[lastIdx] = lastIsUpper ? L'Đ' : L'đ';
            return TransformResult(chars, false);
        } else if (lastLower == L'đ') {
            // Double tap undo: 'đ' + 'd' -> "dd"
            chars[lastIdx] = lastIsUpper ? L'D' : L'd';
            chars.push_back(isUpper ? L'D' : L'd');
            return TransformResult(chars, true);
        }
        return std::nullopt;
    }

    // 2. Circumflex: aa -> â, ee -> ê, oo -> ô
    if (lowerChar == L'a') {
        wchar_t baseLast = VietnameseChar::removeTone(lastChar);
        wchar_t baseLastLower = static_cast<wchar_t>(std::towlower(baseLast));
        Tone currentTone = VietnameseChar::getTone(lastChar);

        if (baseLastLower == L'a') {
            wchar_t targetBase = lastIsUpper ? L'Â' : L'â';
            chars[lastIdx] = VietnameseChar::applyTone(targetBase, currentTone);
            return TransformResult(chars, false);
        } else if (baseLastLower == L'â') {
            // Double tap undo: â + a -> aa
            wchar_t targetBase = lastIsUpper ? L'A' : L'a';
            chars[lastIdx] = VietnameseChar::applyTone(targetBase, currentTone);
            chars.push_back(isUpper ? L'A' : L'a');
            return TransformResult(chars, true);
        }
    }

    if (lowerChar == L'e') {
        wchar_t baseLast = VietnameseChar::removeTone(lastChar);
        wchar_t baseLastLower = static_cast<wchar_t>(std::towlower(baseLast));
        Tone currentTone = VietnameseChar::getTone(lastChar);

        if (baseLastLower == L'e') {
            wchar_t targetBase = lastIsUpper ? L'Ê' : L'ê';
            chars[lastIdx] = VietnameseChar::applyTone(targetBase, currentTone);
            return TransformResult(chars, false);
        } else if (baseLastLower == L'ê') {
            // Double tap undo
            wchar_t targetBase = lastIsUpper ? L'E' : L'e';
            chars[lastIdx] = VietnameseChar::applyTone(targetBase, currentTone);
            chars.push_back(isUpper ? L'E' : L'e');
            return TransformResult(chars, true);
        }
    }

    if (lowerChar == L'o') {
        wchar_t baseLast = VietnameseChar::removeTone(lastChar);
        wchar_t baseLastLower = static_cast<wchar_t>(std::towlower(baseLast));
        Tone currentTone = VietnameseChar::getTone(lastChar);

        if (baseLastLower == L'o') {
            wchar_t targetBase = lastIsUpper ? L'Ô' : L'ô';
            chars[lastIdx] = VietnameseChar::applyTone(targetBase, currentTone);
            return TransformResult(chars, false);
        } else if (baseLastLower == L'ô') {
            // Double tap undo: ô + o -> oo
            wchar_t targetBase = lastIsUpper ? L'O' : L'o';
            chars[lastIdx] = VietnameseChar::applyTone(targetBase, currentTone);
            chars.push_back(isUpper ? L'O' : L'o');
            return TransformResult(chars, true);
        }
    }

    // 3. 'w' transformations (Breve & Horn):
    // aw -> ă, ow -> ơ, uw -> ư, uow -> ươ
    if (lowerChar == L'w') {
        // Check for 'uo' or 'ưo' -> 'ươ'
        if (chars.length() >= 2) {
            size_t secondLastIdx = chars.length() - 2;
            wchar_t c1 = VietnameseChar::removeTone(chars[secondLastIdx]);
            wchar_t c2 = VietnameseChar::removeTone(chars[lastIdx]);
            wchar_t c1Lower = static_cast<wchar_t>(std::towlower(c1));
            wchar_t c2Lower = static_cast<wchar_t>(std::towlower(c2));

            if ((c1Lower == L'u' || c1Lower == L'ư') && c2Lower == L'o') {
                Tone tone = VietnameseChar::getTone(chars[lastIdx]);
                chars[secondLastIdx] = std::iswupper(chars[secondLastIdx]) ? L'Ư' : L'ư';
                wchar_t targetO = std::iswupper(chars[lastIdx]) ? L'Ơ' : L'ơ';
                chars[lastIdx] = VietnameseChar::applyTone(targetO, tone);
                return TransformResult(chars, false);
            } else if (c1Lower == L'ư' && c2Lower == L'ơ') {
                // Undo 'ươ' + 'w' -> 'uow'
                Tone tone = VietnameseChar::getTone(chars[lastIdx]);
                chars[secondLastIdx] = std::iswupper(chars[secondLastIdx]) ? L'U' : L'u';
                wchar_t targetO = std::iswupper(chars[lastIdx]) ? L'O' : L'o';
                chars[lastIdx] = VietnameseChar::applyTone(targetO, tone);
                chars.push_back(isUpper ? L'W' : L'w');
                return TransformResult(chars, true);
            }
        }

        wchar_t baseLast = VietnameseChar::removeTone(lastChar);
        wchar_t baseLastLower = static_cast<wchar_t>(std::towlower(baseLast));
        Tone currentTone = VietnameseChar::getTone(lastChar);

        if (baseLastLower == L'a') {
            wchar_t targetBase = lastIsUpper ? L'Ă' : L'ă';
            chars[lastIdx] = VietnameseChar::applyTone(targetBase, currentTone);
            return TransformResult(chars, false);
        } else if (baseLastLower == L'ă') {
            // Undo ă + w -> aw
            wchar_t targetBase = lastIsUpper ? L'A' : L'a';
            chars[lastIdx] = VietnameseChar::applyTone(targetBase, currentTone);
            chars.push_back(isUpper ? L'W' : L'w');
            return TransformResult(chars, true);
        } else if (baseLastLower == L'o') {
            wchar_t targetBase = lastIsUpper ? L'Ơ' : L'ơ';
            chars[lastIdx] = VietnameseChar::applyTone(targetBase, currentTone);
            return TransformResult(chars, false);
        } else if (baseLastLower == L'ơ') {
            // Undo ơ + w -> ow
            wchar_t targetBase = lastIsUpper ? L'O' : L'o';
            chars[lastIdx] = VietnameseChar::applyTone(targetBase, currentTone);
            chars.push_back(isUpper ? L'W' : L'w');
            return TransformResult(chars, true);
        } else if (baseLastLower == L'u') {
            wchar_t targetBase = lastIsUpper ? L'Ư' : L'ư';
            chars[lastIdx] = VietnameseChar::applyTone(targetBase, currentTone);
            return TransformResult(chars, false);
        } else if (baseLastLower == L'ư') {
            // CHECK: Did this 'ư' come from a standalone 'w' or from 'u' + 'w'?
            std::wstring rawLower = toLowerStr(rawWord);
            if (rawLower == L"w" || (chars.length() == 1 && rawLower.find(L'u') == std::wstring::npos)) {
                // Standalone 'w' -> restore to 'w' (or 'ww')
                return TransformResult(isUpper ? L"W" : L"w", true);
            } else {
                // 'u' then 'w' -> undo to "uw"
                wchar_t targetBase = lastIsUpper ? L'U' : L'u';
                chars[lastIdx] = VietnameseChar::applyTone(targetBase, currentTone);
                chars.push_back(isUpper ? L'W' : L'w');
                return TransformResult(chars, true);
            }
        } else if (inputMethod == InputMethod::Telex) {
            // After a Vietnamese consonant (e.g. "tw" -> "tư", "sw" -> "sư", "chw" -> "chư")
            static const std::unordered_set<wchar_t> validConsonants = {
                L'b', L'c', L'd', L'đ', L'g', L'h', L'k', L'l', L'm', L'n', L'p', L'r', L's', L't', L'v', L'x',
                L'B', L'C', L'D', L'Đ', L'G', L'H', L'K', L'L', L'M', L'N', L'P', L'R', L'S', L'T', L'V', L'X'
            };
            if (validConsonants.find(lastChar) != validConsonants.end()) {
                chars.push_back(isUpper ? L'Ư' : L'ư');
                return TransformResult(chars, false);
            }
            return std::nullopt;
        }
    }

    // 4. Bracket shortcuts in Telex: [ -> ơ, ] -> ư, { -> Ơ, } -> Ư
    if (inputMethod == InputMethod::Telex || inputMethod == InputMethod::SimpleTelex) {
        if (ch == L'[') {
            if (lastChar == L'ơ') {
                chars[lastIdx] = L'[';
                return TransformResult(chars, true);
            }
            chars.push_back(L'ơ');
            return TransformResult(chars, false);
        } else if (ch == L']') {
            if (lastChar == L'ư') {
                chars[lastIdx] = L']';
                return TransformResult(chars, true);
            }
            chars.push_back(L'ư');
            return TransformResult(chars, false);
        } else if (ch == L'{') {
            if (lastChar == L'Ơ') {
                chars[lastIdx] = L'{';
                return TransformResult(chars, true);
            }
            chars.push_back(L'Ơ');
            return TransformResult(chars, false);
        } else if (ch == L'}') {
            if (lastChar == L'Ư') {
                chars[lastIdx] = L'}';
                return TransformResult(chars, true);
            }
            chars.push_back(L'Ư');
            return TransformResult(chars, false);
        }
    }

    return std::nullopt;
}

std::optional<TransformResult> DiacriticTransform::tryApplyTone(
    const std::wstring& word,
    wchar_t ch,
    ToneStyle toneStyle
) {
    wchar_t lowerChar = static_cast<wchar_t>(std::towlower(ch));
    std::optional<Tone> tone = std::nullopt;

    switch (lowerChar) {
    case L's': tone = Tone::Acute; break;
    case L'f': tone = Tone::Grave; break;
    case L'r': tone = Tone::Hook; break;
    case L'x': tone = Tone::Tilde; break;
    case L'j': tone = Tone::Heavy; break;
    case L'z': tone = Tone::None; break;
    default:   tone = std::nullopt; break;
    }

    if (!tone.has_value()) return std::nullopt;
    Tone targetTone = tone.value();

    // Find existing tone in word if any
    Tone currentTone = Tone::None;
    for (wchar_t c : word) {
        Tone t = VietnameseChar::getTone(c);
        if (t != Tone::None) {
            currentTone = t;
            break;
        }
    }

    // Double tap same tone key: e.g. "cá" + 's' -> toggle off to "cas"
    if (targetTone != Tone::None && currentTone == targetTone) {
        std::wstring cleanWord;
        cleanWord.reserve(word.length() + 1);
        for (wchar_t c : word) {
            cleanWord.push_back(VietnameseChar::removeTone(c));
        }
        cleanWord.push_back(ch);
        return TransformResult(cleanWord, true);
    }

    // Remove any existing tone first
    std::wstring cleanWord;
    cleanWord.reserve(word.length());
    for (wchar_t c : word) {
        cleanWord.push_back(VietnameseChar::removeTone(c));
    }

    if (targetTone == Tone::None) {
        // 'z' pressed -> remove tone
        if (currentTone != Tone::None) {
            return TransformResult(cleanWord, true);
        }
        return std::nullopt;
    }

    // Locate target vowel for the tone
    auto targetIndex = ToneRule::findToneTargetIndex(cleanWord, toneStyle);
    if (!targetIndex.has_value()) {
        return std::nullopt;
    }

    std::wstring result = cleanWord;
    size_t idx = targetIndex.value();
    result[idx] = VietnameseChar::applyTone(result[idx], targetTone);

    return TransformResult(result, false);
}

