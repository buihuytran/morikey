#include "VIQRTransform.h"
#include "VietnameseChar.h"
#include "ToneRule.h"
#include <cwctype>

std::optional<std::wstring> VIQRTransform::tryTransformVIQR(
    const std::wstring& word,
    wchar_t ch,
    ToneStyle toneStyle
) {
    if (word.empty()) return std::nullopt;

    std::wstring chars = word;
    size_t lastIdx = chars.length() - 1;
    wchar_t lastChar = chars[lastIdx];
    wchar_t lastLower = static_cast<wchar_t>(std::towlower(lastChar));
    bool lastIsUpper = std::iswupper(lastChar);

    // 1. Circumflex (^): a^ -> â, e^ -> ê, o^ -> ô
    if (ch == L'^') {
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
                chars.push_back(L'^');
                return chars;
            } else if (baseLower == L'ê') {
                chars[i] = VietnameseChar::applyTone(isUp ? L'E' : L'e', tone);
                chars.push_back(L'^');
                return chars;
            } else if (baseLower == L'ô') {
                chars[i] = VietnameseChar::applyTone(isUp ? L'O' : L'o', tone);
                chars.push_back(L'^');
                return chars;
            }
        }
        return std::nullopt;
    }

    // 2. Horn (+ or *): o+ -> ơ, u+ -> ư, uo+ -> ươ
    if (ch == L'+' || ch == L'*') {
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
                chars.push_back(ch);
                return chars;
            }
        }

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
                chars.push_back(ch);
                return chars;
            } else if (baseLower == L'ơ') {
                chars[i] = VietnameseChar::applyTone(isUp ? L'O' : L'o', tone);
                chars.push_back(ch);
                return chars;
            }
        }
        return std::nullopt;
    }

    // 3. Breve ((): a( -> ă
    if (ch == L'(') {
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
                chars.push_back(L'(');
                return chars;
            }
        }
        return std::nullopt;
    }

    // 4. Crossed (- or d): d- -> đ, dd -> đ
    if (ch == L'-') {
        if (lastLower == L'd') {
            chars[lastIdx] = lastIsUpper ? L'Đ' : L'đ';
            return chars;
        } else if (lastLower == L'đ') {
            chars[lastIdx] = lastIsUpper ? L'D' : L'd';
            chars.push_back(L'-');
            return chars;
        }
        return std::nullopt;
    }

    if (static_cast<wchar_t>(std::towlower(ch)) == L'd' && lastLower == L'd') {
        chars[lastIdx] = lastIsUpper ? L'Đ' : L'đ';
        return chars;
    }

    // 5. Tones: ' (sắc), ` (huyền), ? (hỏi), ~ (ngã), . (nặng), 0 (xóa)
    std::optional<Tone> tone = std::nullopt;
    switch (ch) {
    case L'\'': tone = Tone::Acute; break;
    case L'`':  tone = Tone::Grave; break;
    case L'?':  tone = Tone::Hook; break;
    case L'~':  tone = Tone::Tilde; break;
    case L'.':  tone = Tone::Heavy; break;
    case L'0':  tone = Tone::None; break;
    default:    tone = std::nullopt; break;
    }

    if (!tone.has_value()) return std::nullopt;
    Tone targetTone = tone.value();

    Tone currentTone = Tone::None;
    for (wchar_t c : word) {
        Tone t = VietnameseChar::getTone(c);
        if (t != Tone::None) {
            currentTone = t;
            break;
        }
    }

    // Double tap: toggle off and append raw character
    if (targetTone != Tone::None && currentTone == targetTone) {
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

    if (targetTone == Tone::None) {
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
    result[offset] = VietnameseChar::applyTone(result[offset], targetTone);
    return result;
}

