#pragma once

#include "InputMethod.h"
#include <string>
#include <optional>

class VNITransform {
public:
    static std::optional<std::wstring> tryTransformVNI(
        const std::wstring& word,
        wchar_t ch,
        ToneStyle toneStyle
    );
};

