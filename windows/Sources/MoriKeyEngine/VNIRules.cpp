#include "VNIRules.h"
#include "VietnameseChar.h"
#include "ToneRule.h"
#include <cwctype>

std::optional<std::wstring> VNITransform::tryTransformVNI(
    const std::wstring& word,
    wchar_t ch,
    ToneStyle toneStyle
) {
    if (!std::iswdigit(ch)) return std::nullopt;
    if (word.empty()) return std::nullopt;

    std::wstring chars = word;
    size_t lastIdx = chars.length() - 1;
    wchar_t lastChar = chars[lastIdx];
    wchar_t lastLower = static_cast<wchar_t>(std::towlower(lastChar));
    bool lastIsUpper = std::iswupper(lastChar);

    switch (ch) {
    // 9: Đ / đ
    case L'9':
        if (lastLower == L'd') {
            chars[lastIdx] = lastIsUpper ? L'Đ' : L'đ';
            return chars;
        } else if (lastLower == L'đ') {
            chars[lastIdx] = lastIsUpper ? L'D' : L'd';
            chars.push_back(L'9');
            return chars;
        }
        return std::nullopt;

    // 6: Â, Ê, Ô (Circumflex)
    case L'6':
        for (int i = static_cast<int>(chars.length()) - 1; i >= 0; --i) {
            wchar_t base = VietnameseChar::removeTone(chars[i]);
            wchar_t baseLower = static_cast<wchar_t>(std::towlower(base));
            bool isUp = std::iswupper(chars[i]);
            Tone tone = VietnameseChar::getTone(chars[i]);

            if (baseLower == L'a') {
                chars[i] = VietnameseChar::applyTone(isUp ? L'Â' : L'â', tone);
                return chars;
            } else if (baseLower == L'e') {
                chars[i] = VietnameseChar::applyTone(isUp ? L'Ê' : L'ê', tone);
                return chars;
            } else if (baseLower == L'o') {
                chars[i] = VietnameseChar::applyTone(isUp ? L'Ô' : L'ô', tone);
                return chars;
            } else if (baseLower == L'â') {
                chars[i] = VietnameseChar::applyTone(isUp ? L'A' : L'a', tone);
                chars.push_back(L'6');
                return chars;
            } else if (baseLower == L'ê') {
                chars[i] = VietnameseChar::applyTone(isUp ? L'E' : L'e', tone);
                chars.push_back(L'6');
                return chars;
            } else if (baseLower == L'ô') {
                chars[i] = VietnameseChar::applyTone(isUp ? L'O' : L'o', tone);
                chars.push_back(L'6');
                return chars;
            }
        }
        return std::nullopt;

    // 7: Ơ, Ư (Horn)
    case L'7':
        // Check for 'uo' -> 'ươ'
        if (chars.length() >= 2) {
            size_t sIdx = chars.length() - 2;
            wchar_t c1 = VietnameseChar::removeTone(chars[sIdx]);
            wchar_t c2 = VietnameseChar::removeTone(chars[lastIdx]);
            wchar_t c1Lower = static_cast<wchar_t>(std::towlower(c1));
            wchar_t c2Lower = static_cast<wchar_t>(std::towlower(c2));

            if (c1Lower == L'u' && c2Lower == L'o') {
                Tone tone = VietnameseChar::getTone(chars[lastIdx]);
                chars[sIdx] = std::iswupper(chars[sIdx]) ? L'Ư' : L'ư';
                chars[lastIdx] = VietnameseChar::applyTone(std::iswupper(chars[lastIdx]) ? L'Ơ' : L'ơ', tone);
                return chars;
            } else if (c1Lower == L'ư' && c2Lower == L'ơ') {
                Tone tone = VietnameseChar::getTone(chars[lastIdx]);
                chars[sIdx] = std::iswupper(chars[sIdx]) ? L'U' : L'u';
                chars[lastIdx] = VietnameseChar::applyTone(std::iswupper(chars[lastIdx]) ? L'O' : L'o', tone);
                chars.push_back(L'7');
                return chars;
            }
        }

        // Single u -> ư, o -> ơ
        for (int i = static_cast<int>(chars.length()) - 1; i >= 0; --i) {
            wchar_t base = VietnameseChar::removeTone(chars[i]);
            wchar_t baseLower = static_cast<wchar_t>(std::towlower(base));
            bool isUp = std::iswupper(chars[i]);
            Tone tone = VietnameseChar::getTone(chars[i]);

            if (baseLower == L'u') {
                chars[i] = VietnameseChar::applyTone(isUp ? L'Ư' : L'ư', tone);
                return chars;
            } else if (baseLower == L'o') {
                chars[i] = VietnameseChar::applyTone(isUp ? L'Ơ' : L'ơ', tone);
                return chars;
            } else if (baseLower == L'ư') {
                chars[i] = VietnameseChar::applyTone(isUp ? L'U' : L'u', tone);
                chars.push_back(L'7');
                return chars;
            } else if (baseLower == L'ơ') {
                chars[i] = VietnameseChar::applyTone(isUp ? L'O' : L'o', tone);
                chars.push_back(L'7');
                return chars;
            }
        }
        return std::nullopt;

    // 8: Ă (Breve)
    case L'8':
        for (int i = static_cast<int>(chars.length()) - 1; i >= 0; --i) {
            wchar_t base = VietnameseChar::removeTone(chars[i]);
            wchar_t baseLower = static_cast<wchar_t>(std::towlower(base));
            bool isUp = std::iswupper(chars[i]);
            Tone tone = VietnameseChar::getTone(chars[i]);

            if (baseLower == L'a') {
                chars[i] = VietnameseChar::applyTone(isUp ? L'Ă' : L'ă', tone);
                return chars;
            } else if (baseLower == L'ă') {
                chars[i] = VietnameseChar::applyTone(isUp ? L'A' : L'a', tone);
                chars.push_back(L'8');
                return chars;
            }
        }
        return std::nullopt;

    // 1..5, 0: Tones
    case L'1':
    case L'2':
    case L'3':
    case L'4':
    case L'5':
    case L'0': {
        Tone tone;
        switch (ch) {
        case L'1': tone = Tone::Acute; break;
        case L'2': tone = Tone::Grave; break;
        case L'3': tone = Tone::Hook; break;
        case L'4': tone = Tone::Tilde; break;
        case L'5': tone = Tone::Heavy; break;
        default:   tone = Tone::None; break;
        }

        Tone currentTone = Tone::None;
        for (wchar_t c : word) {
            Tone t = VietnameseChar::getTone(c);
            if (t != Tone::None) {
                currentTone = t;
                break;
            }
        }

        // Double tap same tone key: restore number
        if (tone != Tone::None && currentTone == tone) {
            std::wstring cleanWord;
            cleanWord.reserve(word.length() + 1);
            for (wchar_t c : word) {
                cleanWord.push_back(VietnameseChar::removeTone(c));
            }
            cleanWord.push_back(ch);
            return cleanWord;
        }

        std::wstring cleanWord;
        cleanWord.reserve(word.length());
        for (wchar_t c : word) {
            cleanWord.push_back(VietnameseChar::removeTone(c));
        }

        if (tone == Tone::None) {
            if (currentTone != Tone::None) {
                return cleanWord;
            }
            return std::nullopt;
        }

        auto targetIndex = ToneRule::findToneTargetIndex(cleanWord, toneStyle);
        if (!targetIndex.has_value()) {
            return std::nullopt;
        }

        std::wstring result = cleanWord;
        size_t offset = targetIndex.value();
        result[offset] = VietnameseChar::applyTone(result[offset], tone);
        return result;
    }

    default:
        return std::nullopt;
    }
}
