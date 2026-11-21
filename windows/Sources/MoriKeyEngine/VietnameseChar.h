#pragma once

#include <string>
#include <vector>
#include <unordered_set>
#include <unordered_map>

enum class Tone {
    None = 0,
    Acute = 1,   // Sắc
    Grave = 2,   // Huyền
    Hook = 3,    // Hỏi
    Tilde = 4,   // Ngã
    Heavy = 5    // Nặng
};

class VietnameseChar {
public:
    struct ToneInfo {
        wchar_t base;
        Tone tone;
    };

    static const std::unordered_set<wchar_t>& getVowels();
    static const std::unordered_map<wchar_t, std::vector<wchar_t>>& getToneMap();
    
    static bool isVowel(wchar_t ch);
    static Tone getTone(wchar_t ch);
    static wchar_t removeTone(wchar_t ch);
    static wchar_t applyTone(wchar_t baseWithDiacritic, Tone tone);

    static wchar_t toUpper(wchar_t ch);
    static wchar_t toLower(wchar_t ch);
    static std::wstring toUpper(const std::wstring& str);
    static std::wstring toLower(const std::wstring& str);

private:
    static const std::unordered_map<wchar_t, ToneInfo>& getCharToToneInfo();
};
