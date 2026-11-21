#pragma once

#include <string>
#include <unordered_map>
#include <optional>

struct MacroItem {
    std::wstring shortcut;
    std::wstring replacement;
};

class MacroEngine {
public:
    bool isEnabled = false;
    std::unordered_map<std::wstring, std::wstring> macros;

    MacroEngine(bool enabled = false) : isEnabled(enabled) {}

    std::optional<std::wstring> lookup(const std::wstring& word) const;
};

