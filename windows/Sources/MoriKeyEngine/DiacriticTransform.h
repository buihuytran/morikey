#pragma once

#include "InputMethod.h"
#include <string>
#include <optional>

struct TransformResult {
    std::wstring text;
    bool isUndo;

    TransformResult(std::wstring t, bool undo = false)
        : text(std::move(t)), isUndo(undo) {}

    bool operator==(const TransformResult& other) const {
        return text == other.text && isUndo == other.isUndo;
    }
};

class DiacriticTransform {
public:
    static std::optional<TransformResult> tryTransformVowel(
        const std::wstring& word,
        const std::wstring& rawWord,
        wchar_t ch,
        InputMethod inputMethod,
        bool wAtWordStartAsW = true
    );

    static std::optional<TransformResult> tryApplyTone(
        const std::wstring& word,
        wchar_t ch,
        ToneStyle toneStyle
    );
};

