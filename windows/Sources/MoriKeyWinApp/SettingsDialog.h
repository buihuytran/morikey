#pragma once

#include <windows.h>
#include <commctrl.h>

class SettingsDialog {
public:
    static SettingsDialog& instance();

    void show(HWND hParent, HINSTANCE hInstance);
    void hide();
    bool isVisible() const { return m_hWnd != NULL && IsWindow(m_hWnd); }

    LRESULT handleMessage(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

private:
    SettingsDialog();
    ~SettingsDialog();

    HWND m_hWnd = NULL;
    HWND m_hTab = NULL;
    HINSTANCE m_hInstance = NULL;

    // Controls on tabs
    void createTabControls(HWND hWnd);
    void updateTabVisibility(int tabIndex);
    void loadValuesToUI();
    void saveValuesFromUI();
    void refreshMacroList();

    int m_currentTab = 0;
};

