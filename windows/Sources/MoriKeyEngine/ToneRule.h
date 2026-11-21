#pragma once

#include "InputMethod.h"
#include <string>
#include <optional>

class ToneRule {
public:
    /// Determines the best index in `word` (among vowels) to place the tone
    static std::optional<size_t> findToneTargetIndex(const std::wstring& word, ToneStyle toneStyle);

    /// When a consonant is added, reposition tone if needed (e.g. "tỏa" + "n" -> "toản")
    static std::wstring repositionTone(const std::wstring& word, ToneStyle toneStyle);
};

