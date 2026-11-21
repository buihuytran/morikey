#pragma once

#include <windows.h>
#include <functional>
#include "../MoriKeyEngine/MoriEngine.h"

class KeyboardHook {
public:
    static KeyboardHook& instance();

    bool install(HINSTANCE hInstance);
    void uninstall();

    void setEngine(MoriEngine* engine) { m_engine = engine; }
    void setModeToggleCallback(std::function<void(bool)> callback) { m_onModeToggled = std::move(callback); }

    LRESULT handleKeyboard(int nCode, WPARAM wParam, LPARAM lParam);
    LRESULT handleMouse(int nCode, WPARAM wParam, LPARAM lParam);

private:
    KeyboardHook();
    ~KeyboardHook();

    HHOOK m_hKeyboardHook = NULL;
    HHOOK m_hMouseHook = NULL;
    MoriEngine* m_engine = nullptr;
    std::function<void(bool)> m_onModeToggled;

    bool checkHotkey(DWORD vkCode, bool isCtrl, bool isAlt, bool isShift);
};

