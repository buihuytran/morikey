#pragma once

#include <string>

enum class InputMethod {
    Telex = 0,
    SimpleTelex = 1,
    VNI = 2,
    VIQR = 3
};

enum class ToneStyle {
    Modern = 0, // hòa, thúy, khỏe
    Classic = 1 // hoà, thuý, khoẻ
};

inline const wchar_t* getInputMethodName(InputMethod method) {
    switch (method) {
    case InputMethod::Telex: return L"Telex";
    case InputMethod::SimpleTelex: return L"Simple Telex";
    case InputMethod::VNI: return L"VNI";
    case InputMethod::VIQR: return L"VIQR";
    default: return L"Telex";
    }
}

inline const wchar_t* getToneStyleName(ToneStyle style) {
    switch (style) {
    case ToneStyle::Modern: return L"Kiểu mới (hòa, thúy)";
    case ToneStyle::Classic: return L"Kiểu cũ (hoà, thuý)";
    default: return L"Kiểu mới (hòa, thúy)";
    }
}

