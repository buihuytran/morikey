#pragma once

#include <windows.h>
#include <string>
#include <vector>
#include "../MoriKeyEngine/InputMethod.h"
#include "../MoriKeyEngine/MacroEngine.h"

enum class ShortcutOption {
    CtrlSpace = 0,
    AltZ = 1,
    CtrlShift = 2
};

class AppSettings {
public:
    static AppSettings& instance();

    bool isEnabled = true;
    InputMethod inputMethod = InputMethod::Telex;
    ToneStyle toneStyle = ToneStyle::Modern;
    bool isSpellingCheckEnabled = true;
    bool wAtWordStartAsW = true;
    bool fixBrowserSuggestions = true;
    bool isMacroEnabled = false;
    ShortcutOption shortcutOption = ShortcutOption::CtrlSpace;
    bool launchAtLogin = false;
    std::vector<MacroItem> macroItems;

    void load();
    void save();
    void setLaunchAtLogin(bool enable);
    bool checkLaunchAtLogin();

    std::wstring getSettingsPath() const;

private:
    AppSettings();
    void loadFromRegistry();
    void saveToRegistry();
    void loadMacros();
    void saveMacros();
};

