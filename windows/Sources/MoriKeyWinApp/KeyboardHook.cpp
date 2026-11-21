#include "KeyboardHook.h"
#include "KeySimulator.h"
#include "AppSettings.h"

static bool isForegroundBrowser() {
    HWND hWnd = GetForegroundWindow();
    if (!hWnd) return false;

    wchar_t className[256] = { 0 };
    GetClassNameW(hWnd, className, 256);

    // Chrome, Edge, Brave, Opera, Vivaldi, Cốc Cốc, Firefox
    if (wcsstr(className, L"Chrome_WidgetWin") != NULL ||
        wcsstr(className, L"Chrome_RenderWidgetHost") != NULL ||
        wcsstr(className, L"MozillaWindowClass") != NULL) {
        return true;
    }

    DWORD pid = 0;
    GetWindowThreadProcessId(hWnd, &pid);
    if (pid != 0) {
        HANDLE hProcess = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
        if (hProcess) {
            wchar_t exePath[MAX_PATH] = { 0 };
            DWORD size = MAX_PATH;
            if (QueryFullProcessImageNameW(hProcess, 0, exePath, &size)) {
                for (DWORD i = 0; i < size; ++i) {
                    exePath[i] = static_cast<wchar_t>(towlower(exePath[i]));
                }
                if (wcsstr(exePath, L"chrome.exe") ||
                    wcsstr(exePath, L"msedge.exe") ||
                    wcsstr(exePath, L"brave.exe") ||
                    wcsstr(exePath, L"opera.exe") ||
                    wcsstr(exePath, L"vivaldi.exe") ||
                    wcsstr(exePath, L"browser.exe") ||
                    wcsstr(exePath, L"firefox.exe")) {
                    CloseHandle(hProcess);
                    return true;
                }
            }
            CloseHandle(hProcess);
        }
    }
    return false;
}

static LRESULT CALLBACK LowLevelKeyboardProc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode == HC_ACTION) {
        LRESULT res = KeyboardHook::instance().handleKeyboard(nCode, wParam, lParam);
        if (res != 0) {
            return res; // Swallow key
        }
    }
    return CallNextHookEx(NULL, nCode, wParam, lParam);
}

static LRESULT CALLBACK LowLevelMouseProc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode == HC_ACTION) {
        KeyboardHook::instance().handleMouse(nCode, wParam, lParam);
    }
    return CallNextHookEx(NULL, nCode, wParam, lParam);
}

KeyboardHook& KeyboardHook::instance() {
    static KeyboardHook s_instance;
    return s_instance;
}

KeyboardHook::KeyboardHook() {}

KeyboardHook::~KeyboardHook() {
    uninstall();
}

bool KeyboardHook::install(HINSTANCE hInstance) {
    if (m_hKeyboardHook != NULL) return true;

    m_hKeyboardHook = SetWindowsHookExW(
        WH_KEYBOARD_LL,
        LowLevelKeyboardProc,
        hInstance,
        0
    );

    m_hMouseHook = SetWindowsHookExW(
        WH_MOUSE_LL,
        LowLevelMouseProc,
        hInstance,
        0
    );

    return (m_hKeyboardHook != NULL);
}

void KeyboardHook::uninstall() {
    if (m_hKeyboardHook != NULL) {
        UnhookWindowsHookEx(m_hKeyboardHook);
        m_hKeyboardHook = NULL;
    }
    if (m_hMouseHook != NULL) {
        UnhookWindowsHookEx(m_hMouseHook);
        m_hMouseHook = NULL;
    }
}

LRESULT KeyboardHook::handleMouse(int nCode, WPARAM wParam, LPARAM lParam) {
    if (wParam == WM_LBUTTONDOWN || wParam == WM_RBUTTONDOWN || wParam == WM_MBUTTONDOWN) {
        if (m_engine) {
            m_engine->reset();
        }
    }
    return 0;
}

bool KeyboardHook::checkHotkey(DWORD vkCode, bool isCtrl, bool isAlt, bool isShift) {
    auto opt = AppSettings::instance().shortcutOption;
    switch (opt) {
    case ShortcutOption::CtrlSpace:
        if (isCtrl && vkCode == VK_SPACE) return true;
        break;
    case ShortcutOption::AltZ:
        if (isAlt && (vkCode == 'Z' || vkCode == 'z')) return true;
        break;
    case ShortcutOption::CtrlShift:
        if (isCtrl && (vkCode == VK_SHIFT || vkCode == VK_LSHIFT || vkCode == VK_RSHIFT)) return true;
        break;
    }
    return false;
}

LRESULT KeyboardHook::handleKeyboard(int nCode, WPARAM wParam, LPARAM lParam) {
    if (!m_engine) return 0;

    KBDLLHOOKSTRUCT* pKbd = reinterpret_cast<KBDLLHOOKSTRUCT*>(lParam);

    // Ignore events that MoriKey simulated!
    if (pKbd->dwExtraInfo == MORI_EVENT_TAG) {
        return 0;
    }

    bool isKeyDown = (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN);
    bool isKeyUp = (wParam == WM_KEYUP || wParam == WM_SYSKEYUP);

    bool isCtrl = (GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0;
    bool isAlt = (GetAsyncKeyState(VK_MENU) & 0x8000) != 0;
    bool isShift = (GetAsyncKeyState(VK_SHIFT) & 0x8000) != 0;
    bool isWin = (GetAsyncKeyState(VK_LWIN) & 0x8000) != 0 || (GetAsyncKeyState(VK_RWIN) & 0x8000) != 0;

    if (isKeyDown) {
        // Check global hotkey to toggle mode
        if (checkHotkey(pKbd->vkCode, isCtrl, isAlt, isShift)) {
            bool newState = !AppSettings::instance().isEnabled;
            AppSettings::instance().isEnabled = newState;
            m_engine->isEnabled = newState;
            AppSettings::instance().save();
            if (m_onModeToggled) {
                m_onModeToggled(newState);
            }
            return 1; // Swallow toggle hotkey
        }

        // If Windows or Ctrl or Alt is held (shortcuts like Ctrl+C, Ctrl+V, Alt+Tab, Win+R), reset buffer and let it pass through
        if ((isCtrl && pKbd->vkCode != VK_SPACE) || isAlt || isWin) {
            m_engine->reset();
            return 0;
        }

        // Handle Backspace
        if (pKbd->vkCode == VK_BACK) {
            m_engine->handleBackspace();
            return 0;
        }

        // Handle Escape / Enter / Tab / Arrows
        if (pKbd->vkCode == VK_ESCAPE || pKbd->vkCode == VK_RETURN ||
            pKbd->vkCode == VK_TAB || (pKbd->vkCode >= VK_LEFT && pKbd->vkCode <= VK_DOWN)) {
            m_engine->reset();
            return 0;
        }

        // If Vietnamese engine is OFF, pass through
        if (!m_engine->isEnabled) {
            return 0;
        }

        // Translate virtual key to character
        BYTE keyboardState[256];
        GetKeyboardState(keyboardState);

        // Update shift state in keyboardState
        keyboardState[VK_SHIFT] = isShift ? 0x80 : 0;
        keyboardState[VK_CONTROL] = 0;
        keyboardState[VK_MENU] = 0;

        HWND foregroundWnd = GetForegroundWindow();
        DWORD threadId = GetWindowThreadProcessId(foregroundWnd, NULL);
        HKL hkl = GetKeyboardLayout(threadId);

        wchar_t unicodeChar[4] = { 0 };
        int charsRet = ToUnicodeEx(pKbd->vkCode, pKbd->scanCode, keyboardState, unicodeChar, 4, 0, hkl);

        if (charsRet == 1) {
            wchar_t ch = unicodeChar[0];
            TypingAction action = m_engine->process(ch);

            switch (action.type) {
            case TypingAction::Type::PassThrough:
                return 0; // Let keystroke go to foreground app

            case TypingAction::Type::Replace: {
                // Swallow original keypress
                bool isBrowser = AppSettings::instance().fixBrowserSuggestions && isForegroundBrowser();
                KeySimulator::replaceText(action.deleteCount, action.text, isBrowser);
                return 1; // Swallow
            }
            }
        }
    }

    return 0;
}

