#pragma once

#include <windows.h>
#include <shellapi.h>
#include <functional>
#include <string>

#define WM_TRAYICON (WM_USER + 101)

class TrayIcon {
public:
    static TrayIcon& instance();

    bool init(HWND hWnd, HINSTANCE hInstance);
    void update(bool isVietnamese);
    void showContextMenu(HWND hWnd);
    void remove();

    void setToggleCallback(std::function<void()> callback) { m_onToggle = std::move(callback); }
    void setOpenSettingsCallback(std::function<void()> callback) { m_onOpenSettings = std::move(callback); }
    void setMethodCallback(std::function<void(int)> callback) { m_onSelectMethod = std::move(callback); }
    void setToneStyleCallback(std::function<void(int)> callback) { m_onSelectToneStyle = std::move(callback); }

    HICON createBadgeIcon(wchar_t letter, COLORREF bgColor, COLORREF textColor);

private:
    TrayIcon();
    ~TrayIcon();

    HWND m_hWnd = NULL;
    HINSTANCE m_hInstance = NULL;
    NOTIFYICONDATAW m_nid = { 0 };
    HICON m_hIconV = NULL;
    HICON m_hIconE = NULL;

    std::function<void()> m_onToggle;
    std::function<void()> m_onOpenSettings;
    std::function<void(int)> m_onSelectMethod;
    std::function<void(int)> m_onSelectToneStyle;
};

