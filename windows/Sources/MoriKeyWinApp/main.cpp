#include <windows.h>
#include <commctrl.h>
#include "AppSettings.h"
#include "KeyboardHook.h"
#include "TrayIcon.h"
#include "SettingsDialog.h"
#include "../MoriKeyEngine/MoriEngine.h"

#pragma comment(lib, "comctl32.lib")
#pragma comment(lib, "shell32.lib")

static const wchar_t* HIDDEN_WINDOW_CLASS = L"MoriKey_Message_Window";
static MoriEngine g_engine;

static void syncEngineSettings() {
    auto& s = AppSettings::instance();
    g_engine.isEnabled = s.isEnabled;
    g_engine.inputMethod = s.inputMethod;
    g_engine.toneStyle = s.toneStyle;
    g_engine.isSpellingCheckEnabled = s.isSpellingCheckEnabled;
    g_engine.wAtWordStartAsW = s.wAtWordStartAsW;
    g_engine.macroEngine.isEnabled = s.isMacroEnabled;
    g_engine.macroEngine.macros.clear();
    for (const auto& item : s.macroItems) {
        g_engine.macroEngine.macros[item.shortcut] = item.replacement;
    }
}

static LRESULT CALLBACK HiddenWndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_TRAYICON: {
        UINT uMsg = LOWORD(lParam);
        if (uMsg == WM_RBUTTONUP) {
            TrayIcon::instance().showContextMenu(hWnd);
        } else if (uMsg == WM_LBUTTONUP) {
            // Left click: Toggle Vietnamese / English
            bool newState = !AppSettings::instance().isEnabled;
            AppSettings::instance().isEnabled = newState;
            AppSettings::instance().save();
            syncEngineSettings();
            TrayIcon::instance().update(newState);
        } else if (uMsg == WM_LBUTTONDBLCLK) {
            // Double click: Open Settings Window
            SettingsDialog::instance().show(NULL, GetModuleHandle(NULL));
        }
        break;
    }

    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }

    return DefWindowProcW(hWnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PWSTR pCmdLine, int nCmdShow) {
    // 1. Single Instance Check via Mutex
    HANDLE hMutex = CreateMutexW(NULL, TRUE, L"MoriKey_Windows_SingleInstance_Mutex");
    if (GetLastError() == ERROR_ALREADY_EXISTS) {
        // App is already running; open settings window of running instance if possible
        HWND hExisting = FindWindowW(L"MoriKey_Settings_Class", NULL);
        if (hExisting) {
            ShowWindow(hExisting, SW_RESTORE);
            SetForegroundWindow(hExisting);
        }
        CloseHandle(hMutex);
        return 0;
    }

    // 2. Initialize Common Controls
    INITCOMMONCONTROLSEX icex;
    icex.dwSize = sizeof(INITCOMMONCONTROLSEX);
    icex.dwICC = ICC_TAB_CLASSES | ICC_LISTVIEW_CLASSES | ICC_STANDARD_CLASSES;
    InitCommonControlsEx(&icex);

    // 3. Register Hidden Window Class
    WNDCLASSEXW wc = { 0 };
    wc.cbSize = sizeof(WNDCLASSEXW);
    wc.lpfnWndProc = HiddenWndProc;
    wc.hInstance = hInstance;
    wc.lpszClassName = HIDDEN_WINDOW_CLASS;
    RegisterClassExW(&wc);

    HWND hHiddenWnd = CreateWindowExW(
        0, HIDDEN_WINDOW_CLASS, L"MoriKey_Hidden",
        0, 0, 0, 0, 0,
        HWND_MESSAGE, NULL, hInstance, NULL
    );

    // 4. Load settings & initialize engine
    syncEngineSettings();

    // 5. Initialize Tray Icon
    TrayIcon::instance().init(hHiddenWnd, hInstance);
    TrayIcon::instance().setToggleCallback([hHiddenWnd]() {
        bool newState = !AppSettings::instance().isEnabled;
        AppSettings::instance().isEnabled = newState;
        AppSettings::instance().save();
        syncEngineSettings();
        TrayIcon::instance().update(newState);
    });
    TrayIcon::instance().setOpenSettingsCallback([hInstance]() {
        SettingsDialog::instance().show(NULL, hInstance);
    });
    TrayIcon::instance().setMethodCallback([](int methodIdx) {
        AppSettings::instance().inputMethod = static_cast<InputMethod>(methodIdx);
        AppSettings::instance().save();
        syncEngineSettings();
    });
    TrayIcon::instance().setToneStyleCallback([](int toneIdx) {
        AppSettings::instance().toneStyle = static_cast<ToneStyle>(toneIdx);
        AppSettings::instance().save();
        syncEngineSettings();
    });

    // 6. Install Low-Level Keyboard and Mouse Hooks
    KeyboardHook::instance().setEngine(&g_engine);
    KeyboardHook::instance().setModeToggleCallback([](bool isVietnamese) {
        TrayIcon::instance().update(isVietnamese);
    });
    KeyboardHook::instance().install(hInstance);

    // 7. Message Loop
    MSG msg;
    while (GetMessageW(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }

    // 8. Cleanup
    KeyboardHook::instance().uninstall();
    TrayIcon::instance().remove();
    CloseHandle(hMutex);

    return (int)msg.wParam;
}

