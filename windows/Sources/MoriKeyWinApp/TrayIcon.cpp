#include "TrayIcon.h"
#include "AppSettings.h"
#include <commctrl.h>

#define ID_TRAY_TOGGLE          2001
#define ID_TRAY_METHOD_TELEX    2002
#define ID_TRAY_METHOD_STELEX   2003
#define ID_TRAY_METHOD_VNI      2004
#define ID_TRAY_METHOD_VIQR     2005
#define ID_TRAY_TONE_MODERN     2006
#define ID_TRAY_TONE_CLASSIC    2007
#define ID_TRAY_SPELLING        2008
#define ID_TRAY_STARTUP         2009
#define ID_TRAY_SETTINGS        2010
#define ID_TRAY_EXIT            2011

TrayIcon& TrayIcon::instance() {
    static TrayIcon s_instance;
    return s_instance;
}

TrayIcon::TrayIcon() {}

TrayIcon::~TrayIcon() {
    remove();
}

HICON TrayIcon::createBadgeIcon(wchar_t letter, COLORREF bgColor, COLORREF textColor) {
    int iconSize = GetSystemMetrics(SM_CXSMICON);
    if (iconSize <= 0) iconSize = 16;

    HDC hdcScreen = GetDC(NULL);
    HDC hdcMem = CreateCompatibleDC(hdcScreen);
    HDC hdcMask = CreateCompatibleDC(hdcScreen);

    BITMAPINFO bmi = { 0 };
    bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bmi.bmiHeader.biWidth = iconSize;
    bmi.bmiHeader.biHeight = iconSize;
    bmi.bmiHeader.biPlanes = 1;
    bmi.bmiHeader.biBitCount = 32;
    bmi.bmiHeader.biCompression = BI_RGB;

    void* pBits = nullptr;
    HBITMAP hbmColor = CreateDIBSection(hdcMem, &bmi, DIB_RGB_COLORS, &pBits, NULL, 0);
    HBITMAP hbmMask = CreateBitmap(iconSize, iconSize, 1, 1, NULL);

    HBITMAP hOldColor = (HBITMAP)SelectObject(hdcMem, hbmColor);
    HBITMAP hOldMask = (HBITMAP)SelectObject(hdcMask, hbmMask);

    // Fill background of mask with 1 (transparent)
    RECT rc = { 0, 0, iconSize, iconSize };
    HBRUSH hbrWhite = (HBRUSH)GetStockObject(WHITE_BRUSH);
    HBRUSH hbrBlack = (HBRUSH)GetStockObject(BLACK_BRUSH);
    FillRect(hdcMask, &rc, hbrWhite);

    // Draw rounded badge in color DC
    HBRUSH hbrBg = CreateSolidBrush(bgColor);
    HPEN hPen = CreatePen(PS_SOLID, 1, bgColor);
    HBRUSH hOldBrush = (HBRUSH)SelectObject(hdcMem, hbrBg);
    HPEN hOldPen = (HPEN)SelectObject(hdcMem, hPen);

    int corner = iconSize / 4;
    RoundRect(hdcMem, 0, 0, iconSize, iconSize, corner, corner);
    // Draw badge area in mask (black = opaque)
    SelectObject(hdcMask, hbrBlack);
    SelectObject(hdcMask, GetStockObject(BLACK_PEN));
    RoundRect(hdcMask, 0, 0, iconSize, iconSize, corner, corner);

    // Draw text letter in center
    SetBkMode(hdcMem, TRANSPARENT);
    SetTextColor(hdcMem, textColor);

    HFONT hFont = CreateFontW(
        -iconSize * 3 / 4, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE,
        DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_SWISS, L"Segoe UI"
    );
    HFONT hOldFont = (HFONT)SelectObject(hdcMem, hFont);

    wchar_t szText[2] = { letter, 0 };
    DrawTextW(hdcMem, szText, 1, &rc, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

    SelectObject(hdcMem, hOldFont);
    DeleteObject(hFont);
    SelectObject(hdcMem, hOldBrush);
    SelectObject(hdcMem, hOldPen);
    DeleteObject(hbrBg);
    DeleteObject(hPen);

    SelectObject(hdcMem, hOldColor);
    SelectObject(hdcMask, hOldMask);
    DeleteDC(hdcMem);
    DeleteDC(hdcMask);
    ReleaseDC(NULL, hdcScreen);

    ICONINFO ii = { 0 };
    ii.fIcon = TRUE;
    ii.hbmMask = hbmMask;
    ii.hbmColor = hbmColor;

    HICON hIcon = CreateIconIndirect(&ii);

    DeleteObject(hbmColor);
    DeleteObject(hbmMask);

    return hIcon;
}

bool TrayIcon::init(HWND hWnd, HINSTANCE hInstance) {
    m_hWnd = hWnd;
    m_hInstance = hInstance;

    // Create dynamic badges:
    // [V] -> Bright Crimson Red background (RGB(214, 40, 40)), crisp White letter
    m_hIconV = createBadgeIcon(L'V', RGB(220, 38, 38), RGB(255, 255, 255));
    // [E] -> Slate Blue background (RGB(37, 99, 235)), crisp White letter
    m_hIconE = createBadgeIcon(L'E', RGB(37, 99, 235), RGB(255, 255, 255));

    ZeroMemory(&m_nid, sizeof(m_nid));
    m_nid.cbSize = sizeof(NOTIFYICONDATAW);
    m_nid.hWnd = hWnd;
    m_nid.uID = 1;
    m_nid.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
    m_nid.uCallbackMessage = WM_TRAYICON;
    m_nid.hIcon = AppSettings::instance().isEnabled ? m_hIconV : m_hIconE;

    wcscpy_s(m_nid.szTip, AppSettings::instance().isEnabled
        ? L"MoriKey: Tiếng Việt [V] (Click để đổi sang Anh)"
        : L"MoriKey: Tiếng Anh [E] (Click để đổi sang Việt)");

    return Shell_NotifyIconW(NIM_ADD, &m_nid);
}

void TrayIcon::update(bool isVietnamese) {
    m_nid.hIcon = isVietnamese ? m_hIconV : m_hIconE;
    wcscpy_s(m_nid.szTip, isVietnamese
        ? L"MoriKey: Tiếng Việt [V] (Click để đổi sang Anh)"
        : L"MoriKey: Tiếng Anh [E] (Click để đổi sang Việt)");
    Shell_NotifyIconW(NIM_MODIFY, &m_nid);
}

void TrayIcon::remove() {
    if (m_nid.hWnd != NULL) {
        Shell_NotifyIconW(NIM_DELETE, &m_nid);
        m_nid.hWnd = NULL;
    }
    if (m_hIconV) {
        DestroyIcon(m_hIconV);
        m_hIconV = NULL;
    }
    if (m_hIconE) {
        DestroyIcon(m_hIconE);
        m_hIconE = NULL;
    }
}

void TrayIcon::showContextMenu(HWND hWnd) {
    POINT pt;
    GetCursorPos(&pt);

    HMENU hMenu = CreatePopupMenu();
    auto& s = AppSettings::instance();

    // 1. Toggle Vietnamese
    std::wstring toggleStr = s.isEnabled ? L"Bộ gõ: Tiếng Việt [V]" : L"Bộ gõ: Tiếng Anh [E]";
    AppendMenuW(hMenu, MF_STRING | (s.isEnabled ? MF_CHECKED : MF_UNCHECKED), ID_TRAY_TOGGLE, toggleStr.c_str());
    AppendMenuW(hMenu, MF_SEPARATOR, 0, NULL);

    // 2. Submenu: Input Method
    HMENU hMethodMenu = CreatePopupMenu();
    AppendMenuW(hMethodMenu, MF_STRING | (s.inputMethod == InputMethod::Telex ? MF_CHECKED : MF_UNCHECKED), ID_TRAY_METHOD_TELEX, L"Telex");
    AppendMenuW(hMethodMenu, MF_STRING | (s.inputMethod == InputMethod::SimpleTelex ? MF_CHECKED : MF_UNCHECKED), ID_TRAY_METHOD_STELEX, L"Simple Telex (w đầu từ)");
    AppendMenuW(hMethodMenu, MF_STRING | (s.inputMethod == InputMethod::VNI ? MF_CHECKED : MF_UNCHECKED), ID_TRAY_METHOD_VNI, L"VNI");
    AppendMenuW(hMethodMenu, MF_STRING | (s.inputMethod == InputMethod::VIQR ? MF_CHECKED : MF_UNCHECKED), ID_TRAY_METHOD_VIQR, L"VIQR");
    AppendMenuW(hMenu, MF_POPUP, (UINT_PTR)hMethodMenu, L"Kiểu gõ");

    // 3. Submenu: Tone Style
    HMENU hToneMenu = CreatePopupMenu();
    AppendMenuW(hToneMenu, MF_STRING | (s.toneStyle == ToneStyle::Modern ? MF_CHECKED : MF_UNCHECKED), ID_TRAY_TONE_MODERN, L"Kiểu mới (hòa, thúy)");
    AppendMenuW(hToneMenu, MF_STRING | (s.toneStyle == ToneStyle::Classic ? MF_CHECKED : MF_UNCHECKED), ID_TRAY_TONE_CLASSIC, L"Kiểu cũ (hoà, thuý)");
    AppendMenuW(hMenu, MF_POPUP, (UINT_PTR)hToneMenu, L"Quy tắc đặt dấu");

    // 4. Quick Toggles
    AppendMenuW(hMenu, MF_STRING | (s.isSpellingCheckEnabled ? MF_CHECKED : MF_UNCHECKED), ID_TRAY_SPELLING, L"Kiểm tra chính tả thông minh");
    AppendMenuW(hMenu, MF_STRING | (s.launchAtLogin ? MF_CHECKED : MF_UNCHECKED), ID_TRAY_STARTUP, L"Khởi động cùng Windows");
    AppendMenuW(hMenu, MF_SEPARATOR, 0, NULL);

    // 5. Settings & Exit
    AppendMenuW(hMenu, MF_STRING, ID_TRAY_SETTINGS, L"Bảng điều khiển... (Cài đặt)");
    AppendMenuW(hMenu, MF_SEPARATOR, 0, NULL);
    AppendMenuW(hMenu, MF_STRING, ID_TRAY_EXIT, L"Thoát");

    SetForegroundWindow(hWnd);
    int cmd = TrackPopupMenu(hMenu, TPM_RETURNCMD | TPM_NONOTIFY, pt.x, pt.y, 0, hWnd, NULL);
    DestroyMenu(hMenu);

    switch (cmd) {
    case ID_TRAY_TOGGLE:
        if (m_onToggle) m_onToggle();
        break;
    case ID_TRAY_METHOD_TELEX:
        if (m_onSelectMethod) m_onSelectMethod(0);
        break;
    case ID_TRAY_METHOD_STELEX:
        if (m_onSelectMethod) m_onSelectMethod(1);
        break;
    case ID_TRAY_METHOD_VNI:
        if (m_onSelectMethod) m_onSelectMethod(2);
        break;
    case ID_TRAY_METHOD_VIQR:
        if (m_onSelectMethod) m_onSelectMethod(3);
        break;
    case ID_TRAY_TONE_MODERN:
        if (m_onSelectToneStyle) m_onSelectToneStyle(0);
        break;
    case ID_TRAY_TONE_CLASSIC:
        if (m_onSelectToneStyle) m_onSelectToneStyle(1);
        break;
    case ID_TRAY_SPELLING:
        s.isSpellingCheckEnabled = !s.isSpellingCheckEnabled;
        s.save();
        break;
    case ID_TRAY_STARTUP:
        s.launchAtLogin = !s.launchAtLogin;
        s.setLaunchAtLogin(s.launchAtLogin);
        break;
    case ID_TRAY_SETTINGS:
        if (m_onOpenSettings) m_onOpenSettings();
        break;
    case ID_TRAY_EXIT:
        PostQuitMessage(0);
        break;
    }
}

