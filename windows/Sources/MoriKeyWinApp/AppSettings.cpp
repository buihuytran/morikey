#include "AppSettings.h"
#include <shlobj.h>
#include <fstream>
#include <sstream>

#define REG_KEY_MORIKEY L"Software\\MoriKey"
#define REG_RUN_KEY L"Software\\Microsoft\\Windows\\CurrentVersion\\Run"

AppSettings& AppSettings::instance() {
    static AppSettings s_instance;
    return s_instance;
}

AppSettings::AppSettings() {
    load();
}

void AppSettings::load() {
    HKEY hKey;
    bool hasConfigured = false;
    if (RegOpenKeyExW(HKEY_CURRENT_USER, REG_KEY_MORIKEY, 0, KEY_READ, &hKey) == ERROR_SUCCESS) {
        DWORD dwVal = 0, dwSz = sizeof(DWORD);
        if (RegQueryValueExW(hKey, L"ConfiguredStartup", NULL, NULL, (LPBYTE)&dwVal, &dwSz) == ERROR_SUCCESS) {
            hasConfigured = (dwVal != 0);
        }
        RegCloseKey(hKey);
    }

    loadFromRegistry();

    if (!hasConfigured) {
        // First run on Windows: default launchAtLogin to true and register to Run
        launchAtLogin = true;
        setLaunchAtLogin(true);
        save();
    } else {
        launchAtLogin = checkLaunchAtLogin();
    }

    loadMacros();
}

void AppSettings::save() {
    saveToRegistry();
    setLaunchAtLogin(launchAtLogin);
    saveMacros();
}

void AppSettings::loadFromRegistry() {
    HKEY hKey;
    if (RegOpenKeyExW(HKEY_CURRENT_USER, REG_KEY_MORIKEY, 0, KEY_READ, &hKey) == ERROR_SUCCESS) {
        DWORD dwValue = 0;
        DWORD dwSize = sizeof(DWORD);

        if (RegQueryValueExW(hKey, L"IsEnabled", NULL, NULL, (LPBYTE)&dwValue, &dwSize) == ERROR_SUCCESS) {
            isEnabled = (dwValue != 0);
        }
        if (RegQueryValueExW(hKey, L"InputMethod", NULL, NULL, (LPBYTE)&dwValue, &dwSize) == ERROR_SUCCESS) {
            inputMethod = static_cast<InputMethod>(dwValue);
        }
        if (RegQueryValueExW(hKey, L"ToneStyle", NULL, NULL, (LPBYTE)&dwValue, &dwSize) == ERROR_SUCCESS) {
            toneStyle = static_cast<ToneStyle>(dwValue);
        }
        if (RegQueryValueExW(hKey, L"SpellingCheck", NULL, NULL, (LPBYTE)&dwValue, &dwSize) == ERROR_SUCCESS) {
            isSpellingCheckEnabled = (dwValue != 0);
        }
        if (RegQueryValueExW(hKey, L"WAtStartAsW", NULL, NULL, (LPBYTE)&dwValue, &dwSize) == ERROR_SUCCESS) {
            wAtWordStartAsW = (dwValue != 0);
        }
        if (RegQueryValueExW(hKey, L"FixBrowserSuggestions", NULL, NULL, (LPBYTE)&dwValue, &dwSize) == ERROR_SUCCESS) {
            fixBrowserSuggestions = (dwValue != 0);
        }
        if (RegQueryValueExW(hKey, L"MacroEnabled", NULL, NULL, (LPBYTE)&dwValue, &dwSize) == ERROR_SUCCESS) {
            isMacroEnabled = (dwValue != 0);
        }
        if (RegQueryValueExW(hKey, L"ShortcutOption", NULL, NULL, (LPBYTE)&dwValue, &dwSize) == ERROR_SUCCESS) {
            shortcutOption = static_cast<ShortcutOption>(dwValue);
        }

        RegCloseKey(hKey);
    }
}

void AppSettings::saveToRegistry() {
    HKEY hKey;
    if (RegCreateKeyExW(HKEY_CURRENT_USER, REG_KEY_MORIKEY, 0, NULL, 0, KEY_WRITE, NULL, &hKey, NULL) == ERROR_SUCCESS) {
        DWORD dwValue = isEnabled ? 1 : 0;
        RegSetValueExW(hKey, L"IsEnabled", 0, REG_DWORD, (const BYTE*)&dwValue, sizeof(DWORD));

        dwValue = static_cast<DWORD>(inputMethod);
        RegSetValueExW(hKey, L"InputMethod", 0, REG_DWORD, (const BYTE*)&dwValue, sizeof(DWORD));

        dwValue = static_cast<DWORD>(toneStyle);
        RegSetValueExW(hKey, L"ToneStyle", 0, REG_DWORD, (const BYTE*)&dwValue, sizeof(DWORD));

        dwValue = isSpellingCheckEnabled ? 1 : 0;
        RegSetValueExW(hKey, L"SpellingCheck", 0, REG_DWORD, (const BYTE*)&dwValue, sizeof(DWORD));

        dwValue = wAtWordStartAsW ? 1 : 0;
        RegSetValueExW(hKey, L"WAtStartAsW", 0, REG_DWORD, (const BYTE*)&dwValue, sizeof(DWORD));

        dwValue = fixBrowserSuggestions ? 1 : 0;
        RegSetValueExW(hKey, L"FixBrowserSuggestions", 0, REG_DWORD, (const BYTE*)&dwValue, sizeof(DWORD));

        dwValue = isMacroEnabled ? 1 : 0;
        RegSetValueExW(hKey, L"MacroEnabled", 0, REG_DWORD, (const BYTE*)&dwValue, sizeof(DWORD));

        dwValue = static_cast<DWORD>(shortcutOption);
        RegSetValueExW(hKey, L"ShortcutOption", 0, REG_DWORD, (const BYTE*)&dwValue, sizeof(DWORD));

        DWORD dwConfigured = 1;
        RegSetValueExW(hKey, L"ConfiguredStartup", 0, REG_DWORD, (const BYTE*)&dwConfigured, sizeof(DWORD));

        RegCloseKey(hKey);
    }
}

bool AppSettings::checkLaunchAtLogin() {
    HKEY hKey;
    bool running = false;
    if (RegOpenKeyExW(HKEY_CURRENT_USER, REG_RUN_KEY, 0, KEY_READ, &hKey) == ERROR_SUCCESS) {
        if (RegQueryValueExW(hKey, L"MoriKey", NULL, NULL, NULL, NULL) == ERROR_SUCCESS) {
            running = true;
        }
        RegCloseKey(hKey);
    }
    return running;
}

void AppSettings::setLaunchAtLogin(bool enable) {
    HKEY hKey;
    if (RegOpenKeyExW(HKEY_CURRENT_USER, REG_RUN_KEY, 0, KEY_WRITE, &hKey) == ERROR_SUCCESS) {
        if (enable) {
            wchar_t szPath[MAX_PATH];
            GetModuleFileNameW(NULL, szPath, MAX_PATH);
            std::wstring quotedPath = L"\"" + std::wstring(szPath) + L"\"";
            RegSetValueExW(hKey, L"MoriKey", 0, REG_SZ, (const BYTE*)quotedPath.c_str(), static_cast<DWORD>((quotedPath.length() + 1) * sizeof(wchar_t)));
        } else {
            RegDeleteValueW(hKey, L"MoriKey");
        }
        RegCloseKey(hKey);
    }
}

std::wstring AppSettings::getSettingsPath() const {
    wchar_t szAppData[MAX_PATH];
    if (SUCCEEDED(SHGetFolderPathW(NULL, CSIDL_APPDATA, NULL, 0, szAppData))) {
        std::wstring dir = std::wstring(szAppData) + L"\\MoriKey";
        CreateDirectoryW(dir.c_str(), NULL);
        return dir + L"\\macros.txt";
    }
    return L"macros.txt";
}

void AppSettings::loadMacros() {
    macroItems.clear();
    std::wstring path = getSettingsPath();
    std::wifstream file(path.c_str());
    if (file.is_open()) {
        std::wstring line;
        while (std::getline(file, line)) {
            size_t sep = line.find(L'\t');
            if (sep != std::wstring::npos) {
                MacroItem item;
                item.shortcut = line.substr(0, sep);
                item.replacement = line.substr(sep + 1);
                macroItems.push_back(item);
            }
        }
    }
}

void AppSettings::saveMacros() {
    std::wstring path = getSettingsPath();
    std::wofstream file(path.c_str());
    if (file.is_open()) {
        for (const auto& item : macroItems) {
            file << item.shortcut << L"\t" << item.replacement << L"\n";
        }
    }
}

