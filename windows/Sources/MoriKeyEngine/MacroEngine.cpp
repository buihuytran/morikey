#include "MacroEngine.h"
#include "VietnameseChar.h"
#include <cwctype>
#include <algorithm>

std::optional<std::wstring> MacroEngine::lookup(const std::wstring& word) const {
    if (!isEnabled || word.empty()) return std::nullopt;

    std::wstring lower = VietnameseChar::toLower(word);
    auto it = macros.find(lower);
    if (it == macros.end()) return std::nullopt;

    const std::wstring& baseReplacement = it->second;

    // All uppercase: VN -> VIỆT NAM
    bool isAllUpper = true;
    for (wchar_t c : word) {
        if (c != VietnameseChar::toUpper(c)) {
            isAllUpper = false;
            break;
        }
    }
    if (isAllUpper && word.length() > 1) {
        return VietnameseChar::toUpper(baseReplacement);
    }

    // Capitalized: Vn -> Việt Nam
    if (word[0] == VietnameseChar::toUpper(word[0]) && !baseReplacement.empty()) {
        std::wstring capitalized = baseReplacement;
        capitalized[0] = VietnameseChar::toUpper(capitalized[0]);
        return capitalized;
    }

    return baseReplacement;
}
