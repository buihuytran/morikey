#pragma once

#include "InputMethod.h"
#include <string>
#include <optional>

class VIQRTransform {
public:
    static std::optional<std::wstring> tryTransformVIQR(
        const std::wstring& word,
        wchar_t ch,
        ToneStyle toneStyle
    );
};

