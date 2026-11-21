#include "SettingsDialog.h"
#include "AppSettings.h"
#include <vector>

#define ID_TAB_CONTROL          3001
#define ID_BTN_CLOSE            3002
#define ID_BTN_APPLY            3003

// General Tab
#define ID_CHK_ENABLED          3101
#define ID_CHK_STARTUP          3102
#define ID_RAD_CTRL_SPACE       3103
#define ID_RAD_ALT_Z            3104
#define ID_RAD_CTRL_SHIFT       3105

// Typing Tab
#define ID_RAD_TELEX            3201
#define ID_RAD_STELEX           3202
#define ID_RAD_VNI              3203
#define ID_RAD_VIQR             3204
#define ID_RAD_TONE_MODERN      3205
#define ID_RAD_TONE_CLASSIC     3206
#define ID_CHK_SPELLING         3207
#define ID_CHK_W_START          3208
#define ID_CHK_FIX_BROWSER      3209

// Macro Tab
#define ID_CHK_MACRO_ENABLED    3301
#define ID_LIST_MACROS          3302
#define ID_EDT_SHORTCUT         3303
#define ID_EDT_REPLACEMENT      3304
#define ID_BTN_MACRO_ADD        3305
#define ID_BTN_MACRO_DEL        3306

static const wchar_t* SETTINGS_CLASS = L"MoriKey_Settings_Class";

static LRESULT CALLBACK SettingsWndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    return SettingsDialog::instance().handleMessage(hWnd, msg, wParam, lParam);
}

SettingsDialog& SettingsDialog::instance() {
    static SettingsDialog s_instance;
    return s_instance;
}

SettingsDialog::SettingsDialog() {}

SettingsDialog::~SettingsDialog() {
    hide();
}

void SettingsDialog::show(HWND hParent, HINSTANCE hInstance) {
    m_hInstance = hInstance;

    if (m_hWnd != NULL && IsWindow(m_hWnd)) {
        ShowWindow(m_hWnd, SW_RESTORE);
        SetForegroundWindow(m_hWnd);
        return;
    }

    WNDCLASSEXW wc = { 0 };
    wc.cbSize = sizeof(WNDCLASSEXW);
    wc.lpfnWndProc = SettingsWndProc;
    wc.hInstance = hInstance;
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_BTNFACE + 1);
    wc.lpszClassName = SETTINGS_CLASS;
    RegisterClassExW(&wc);

    int width = 520;
    int height = 510;
    int screenW = GetSystemMetrics(SM_CXSCREEN);
    int screenH = GetSystemMetrics(SM_CYSCREEN);
    int x = (screenW - width) / 2;
    int y = (screenH - height) / 2;

    m_hWnd = CreateWindowExW(
        WS_EX_DLGMODALFRAME,
        SETTINGS_CLASS,
        L"MoriKey - Bảng điều khiển",
        WS_POPUP | WS_CAPTION | WS_SYSMENU | WS_VISIBLE,
        x, y, width, height,
        hParent, NULL, hInstance, NULL
    );

    createTabControls(m_hWnd);
    loadValuesToUI();
    updateTabVisibility(0);
}

void SettingsDialog::hide() {
    if (m_hWnd != NULL && IsWindow(m_hWnd)) {
        DestroyWindow(m_hWnd);
        m_hWnd = NULL;
    }
}

void SettingsDialog::createTabControls(HWND hWnd) {
    HFONT hFont = (HFONT)GetStockObject(DEFAULT_GUI_FONT);

    // Tab control
    m_hTab = CreateWindowExW(
        0, WC_TABCONTROLW, L"",
        WS_CHILD | WS_CLIPSIBLINGS | WS_VISIBLE,
        15, 15, 475, 400,
        hWnd, (HMENU)ID_TAB_CONTROL, m_hInstance, NULL
    );
    SendMessage(m_hTab, WM_SETFONT, (WPARAM)hFont, TRUE);

    TCITEMW tie = { 0 };
    tie.mask = TCIF_TEXT;

    tie.pszText = (LPWSTR)L"Cơ bản";
    TabCtrl_InsertItem(m_hTab, 0, &tie);
    tie.pszText = (LPWSTR)L"Kiểu gõ";
    TabCtrl_InsertItem(m_hTab, 1, &tie);
    tie.pszText = (LPWSTR)L"Gõ tắt";
    TabCtrl_InsertItem(m_hTab, 2, &tie);
    tie.pszText = (LPWSTR)L"Giới thiệu";
    TabCtrl_InsertItem(m_hTab, 3, &tie);

    // Bottom buttons
    HWND hBtnApply = CreateWindowExW(
        0, L"BUTTON", L"Đóng",
        WS_CHILD | WS_VISIBLE | BS_DEFPUSHBUTTON,
        390, 425, 100, 30,
        hWnd, (HMENU)ID_BTN_CLOSE, m_hInstance, NULL
    );
    SendMessage(hBtnApply, WM_SETFONT, (WPARAM)hFont, TRUE);

    // --- Tab 0: Basic ---
    HWND hGrp1 = CreateWindowExW(0, L"BUTTON", L"Trạng thái hoạt động", WS_CHILD | BS_GROUPBOX, 30, 50, 445, 110, hWnd, NULL, m_hInstance, NULL);
    SendMessage(hGrp1, WM_SETFONT, (WPARAM)hFont, TRUE);
    HWND hChkEnabled = CreateWindowExW(0, L"BUTTON", L"Bật bộ gõ tiếng Việt [V]", WS_CHILD | BS_AUTOCHECKBOX, 45, 75, 300, 24, hWnd, (HMENU)ID_CHK_ENABLED, m_hInstance, NULL);
    SendMessage(hChkEnabled, WM_SETFONT, (WPARAM)hFont, TRUE);
    HWND hChkStartup = CreateWindowExW(0, L"BUTTON", L"Khởi động cùng Windows", WS_CHILD | BS_AUTOCHECKBOX, 45, 110, 300, 24, hWnd, (HMENU)ID_CHK_STARTUP, m_hInstance, NULL);
    SendMessage(hChkStartup, WM_SETFONT, (WPARAM)hFont, TRUE);

    HWND hGrp2 = CreateWindowExW(0, L"BUTTON", L"Phím tắt chuyển đổi Việt / Anh", WS_CHILD | BS_GROUPBOX, 30, 175, 445, 140, hWnd, NULL, m_hInstance, NULL);
    SendMessage(hGrp2, WM_SETFONT, (WPARAM)hFont, TRUE);
    HWND hRad1 = CreateWindowExW(0, L"BUTTON", L"Ctrl + Space (Mặc định)", WS_CHILD | BS_AUTORADIOBUTTON | WS_GROUP, 45, 205, 250, 24, hWnd, (HMENU)ID_RAD_CTRL_SPACE, m_hInstance, NULL);
    SendMessage(hRad1, WM_SETFONT, (WPARAM)hFont, TRUE);
    HWND hRad2 = CreateWindowExW(0, L"BUTTON", L"Alt + Z", WS_CHILD | BS_AUTORADIOBUTTON, 45, 240, 250, 24, hWnd, (HMENU)ID_RAD_ALT_Z, m_hInstance, NULL);
    SendMessage(hRad2, WM_SETFONT, (WPARAM)hFont, TRUE);
    HWND hRad3 = CreateWindowExW(0, L"BUTTON", L"Ctrl + Shift", WS_CHILD | BS_AUTORADIOBUTTON, 45, 275, 250, 24, hWnd, (HMENU)ID_RAD_CTRL_SHIFT, m_hInstance, NULL);
    SendMessage(hRad3, WM_SETFONT, (WPARAM)hFont, TRUE);

    // --- Tab 1: Typing ---
    HWND hGrp3 = CreateWindowExW(0, L"BUTTON", L"Kiểu gõ tiếng Việt", WS_CHILD | BS_GROUPBOX, 30, 50, 445, 140, hWnd, NULL, m_hInstance, NULL);
    SendMessage(hGrp3, WM_SETFONT, (WPARAM)hFont, TRUE);
    HWND hRadTelex = CreateWindowExW(0, L"BUTTON", L"Telex (aa=â, ee=ê, oo=ô, ow=ơ, w=ư, s/f/r/x/j)", WS_CHILD | BS_AUTORADIOBUTTON | WS_GROUP, 45, 75, 380, 24, hWnd, (HMENU)ID_RAD_TELEX, m_hInstance, NULL);
    SendMessage(hRadTelex, WM_SETFONT, (WPARAM)hFont, TRUE);
    HWND hRadSTelex = CreateWindowExW(0, L"BUTTON", L"Simple Telex (Giữ 'w' đầu từ: web, win, wifi)", WS_CHILD | BS_AUTORADIOBUTTON, 45, 105, 380, 24, hWnd, (HMENU)ID_RAD_STELEX, m_hInstance, NULL);
    SendMessage(hRadSTelex, WM_SETFONT, (WPARAM)hFont, TRUE);
    HWND hRadVni = CreateWindowExW(0, L"BUTTON", L"VNI (1..5: dấu thanh, 6: â/ê/ô, 7: ơ/ư, 8: ă, 9: đ)", WS_CHILD | BS_AUTORADIOBUTTON, 45, 135, 380, 24, hWnd, (HMENU)ID_RAD_VNI, m_hInstance, NULL);
    SendMessage(hRadVni, WM_SETFONT, (WPARAM)hFont, TRUE);
    HWND hRadViqr = CreateWindowExW(0, L"BUTTON", L"VIQR (quy tắc ký tự: ', `, ?, ~, ., ^, +, ()", WS_CHILD | BS_AUTORADIOBUTTON, 45, 165, 380, 24, hWnd, (HMENU)ID_RAD_VIQR, m_hInstance, NULL);
    SendMessage(hRadViqr, WM_SETFONT, (WPARAM)hFont, TRUE);

    HWND hGrp4 = CreateWindowExW(0, L"BUTTON", L"Quy tắc dấu & Nhận diện thông minh", WS_CHILD | BS_GROUPBOX, 30, 200, 445, 195, hWnd, NULL, m_hInstance, NULL);
    SendMessage(hGrp4, WM_SETFONT, (WPARAM)hFont, TRUE);
    HWND hRadModern = CreateWindowExW(0, L"BUTTON", L"Kiểu mới: hòa, thúy, khỏe", WS_CHILD | BS_AUTORADIOBUTTON | WS_GROUP, 45, 225, 220, 24, hWnd, (HMENU)ID_RAD_TONE_MODERN, m_hInstance, NULL);
    SendMessage(hRadModern, WM_SETFONT, (WPARAM)hFont, TRUE);
    HWND hRadClassic = CreateWindowExW(0, L"BUTTON", L"Kiểu cũ: hoà, thuý, khoẻ", WS_CHILD | BS_AUTORADIOBUTTON, 250, 225, 200, 24, hWnd, (HMENU)ID_RAD_TONE_CLASSIC, m_hInstance, NULL);
    SendMessage(hRadClassic, WM_SETFONT, (WPARAM)hFont, TRUE);
    HWND hChkSpell = CreateWindowExW(0, L"BUTTON", L"Kiểm tra chính tả & Tự động khôi phục từ tiếng Anh (good, morning...)", WS_CHILD | BS_AUTOCHECKBOX, 45, 255, 410, 24, hWnd, (HMENU)ID_CHK_SPELLING, m_hInstance, NULL);
    SendMessage(hChkSpell, WM_SETFONT, (WPARAM)hFont, TRUE);
    HWND hChkW = CreateWindowExW(0, L"BUTTON", L"Cho phép gõ 'w' ở đầu từ tiếng Anh (giữ nguyên 'w')", WS_CHILD | BS_AUTOCHECKBOX, 45, 285, 410, 24, hWnd, (HMENU)ID_CHK_W_START, m_hInstance, NULL);
    SendMessage(hChkW, WM_SETFONT, (WPARAM)hFont, TRUE);
    HWND hChkBrowser = CreateWindowExW(0, L"BUTTON", L"Khắc phục lỗi dấu trên trình duyệt (Chrome, Edge, Cốc Cốc...)", WS_CHILD | BS_AUTOCHECKBOX, 45, 315, 410, 24, hWnd, (HMENU)ID_CHK_FIX_BROWSER, m_hInstance, NULL);
    SendMessage(hChkBrowser, WM_SETFONT, (WPARAM)hFont, TRUE);

    // --- Tab 2: Macro ---
    HWND hChkMacro = CreateWindowExW(0, L"BUTTON", L"Bật tính năng gõ tắt (Macro)", WS_CHILD | BS_AUTOCHECKBOX, 35, 55, 300, 24, hWnd, (HMENU)ID_CHK_MACRO_ENABLED, m_hInstance, NULL);
    SendMessage(hChkMacro, WM_SETFONT, (WPARAM)hFont, TRUE);

    HWND hList = CreateWindowExW(
        WS_EX_CLIENTEDGE, WC_LISTVIEWW, L"",
        WS_CHILD | LVS_REPORT | LVS_SINGLESEL,
        35, 85, 435, 200,
        hWnd, (HMENU)ID_LIST_MACROS, m_hInstance, NULL
    );
    SendMessage(hList, WM_SETFONT, (WPARAM)hFont, TRUE);
    ListView_SetExtendedListViewStyle(hList, LVS_EX_FULLROWSELECT | LVS_EX_GRIDLINES);

    LVCOLUMNW lvc = { 0 };
    lvc.mask = LVCF_TEXT | LVCF_WIDTH;
    lvc.pszText = (LPWSTR)L"Từ viết tắt";
    lvc.cx = 150;
    ListView_InsertColumn(hList, 0, &lvc);
    lvc.pszText = (LPWSTR)L"Cụm từ thay thế";
    lvc.cx = 265;
    ListView_InsertColumn(hList, 1, &lvc);

    HWND hEdtShort = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"", WS_CHILD, 35, 300, 120, 24, hWnd, (HMENU)ID_EDT_SHORTCUT, m_hInstance, NULL);
    SendMessage(hEdtShort, WM_SETFONT, (WPARAM)hFont, TRUE);
    HWND hEdtRepl = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"", WS_CHILD, 165, 300, 200, 24, hWnd, (HMENU)ID_EDT_REPLACEMENT, m_hInstance, NULL);
    SendMessage(hEdtRepl, WM_SETFONT, (WPARAM)hFont, TRUE);
    HWND hBtnAdd = CreateWindowExW(0, L"BUTTON", L"Thêm", WS_CHILD, 375, 300, 45, 24, hWnd, (HMENU)ID_BTN_MACRO_ADD, m_hInstance, NULL);
    SendMessage(hBtnAdd, WM_SETFONT, (WPARAM)hFont, TRUE);
    HWND hBtnDel = CreateWindowExW(0, L"BUTTON", L"Xóa", WS_CHILD, 425, 300, 45, 24, hWnd, (HMENU)ID_BTN_MACRO_DEL, m_hInstance, NULL);
    SendMessage(hBtnDel, WM_SETFONT, (WPARAM)hFont, TRUE);
}

void SettingsDialog::updateTabVisibility(int tabIndex) {
    m_currentTab = tabIndex;

    // Tab 0 IDs
    static const int tab0Ids[] = { ID_CHK_ENABLED, ID_CHK_STARTUP, ID_RAD_CTRL_SPACE, ID_RAD_ALT_Z, ID_RAD_CTRL_SHIFT };
    // Tab 1 IDs
    static const int tab1Ids[] = { ID_RAD_TELEX, ID_RAD_STELEX, ID_RAD_VNI, ID_RAD_VIQR, ID_RAD_TONE_MODERN, ID_RAD_TONE_CLASSIC, ID_CHK_SPELLING, ID_CHK_W_START, ID_CHK_FIX_BROWSER };
    // Tab 2 IDs
    static const int tab2Ids[] = { ID_CHK_MACRO_ENABLED, ID_LIST_MACROS, ID_EDT_SHORTCUT, ID_EDT_REPLACEMENT, ID_BTN_MACRO_ADD, ID_BTN_MACRO_DEL };

    for (int id : tab0Ids) ShowWindow(GetDlgItem(m_hWnd, id), (tabIndex == 0) ? SW_SHOW : SW_HIDE);
    for (int id : tab1Ids) ShowWindow(GetDlgItem(m_hWnd, id), (tabIndex == 1) ? SW_SHOW : SW_HIDE);
    for (int id : tab2Ids) ShowWindow(GetDlgItem(m_hWnd, id), (tabIndex == 2) ? SW_SHOW : SW_HIDE);

    InvalidateRect(m_hWnd, NULL, TRUE);
}

void SettingsDialog::loadValuesToUI() {
    auto& s = AppSettings::instance();

    // Tab 0
    CheckDlgButton(m_hWnd, ID_CHK_ENABLED, s.isEnabled ? BST_CHECKED : BST_UNCHECKED);
    CheckDlgButton(m_hWnd, ID_CHK_STARTUP, s.launchAtLogin ? BST_CHECKED : BST_UNCHECKED);
    CheckDlgButton(m_hWnd, ID_RAD_CTRL_SPACE, (s.shortcutOption == ShortcutOption::CtrlSpace) ? BST_CHECKED : BST_UNCHECKED);
    CheckDlgButton(m_hWnd, ID_RAD_ALT_Z, (s.shortcutOption == ShortcutOption::AltZ) ? BST_CHECKED : BST_UNCHECKED);
    CheckDlgButton(m_hWnd, ID_RAD_CTRL_SHIFT, (s.shortcutOption == ShortcutOption::CtrlShift) ? BST_CHECKED : BST_UNCHECKED);

    // Tab 1
    CheckDlgButton(m_hWnd, ID_RAD_TELEX, (s.inputMethod == InputMethod::Telex) ? BST_CHECKED : BST_UNCHECKED);
    CheckDlgButton(m_hWnd, ID_RAD_STELEX, (s.inputMethod == InputMethod::SimpleTelex) ? BST_CHECKED : BST_UNCHECKED);
    CheckDlgButton(m_hWnd, ID_RAD_VNI, (s.inputMethod == InputMethod::VNI) ? BST_CHECKED : BST_UNCHECKED);
    CheckDlgButton(m_hWnd, ID_RAD_VIQR, (s.inputMethod == InputMethod::VIQR) ? BST_CHECKED : BST_UNCHECKED);

    CheckDlgButton(m_hWnd, ID_RAD_TONE_MODERN, (s.toneStyle == ToneStyle::Modern) ? BST_CHECKED : BST_UNCHECKED);
    CheckDlgButton(m_hWnd, ID_RAD_TONE_CLASSIC, (s.toneStyle == ToneStyle::Classic) ? BST_CHECKED : BST_UNCHECKED);

    CheckDlgButton(m_hWnd, ID_CHK_SPELLING, s.isSpellingCheckEnabled ? BST_CHECKED : BST_UNCHECKED);
    CheckDlgButton(m_hWnd, ID_CHK_W_START, s.wAtWordStartAsW ? BST_CHECKED : BST_UNCHECKED);
    CheckDlgButton(m_hWnd, ID_CHK_FIX_BROWSER, s.fixBrowserSuggestions ? BST_CHECKED : BST_UNCHECKED);

    // Tab 2
    CheckDlgButton(m_hWnd, ID_CHK_MACRO_ENABLED, s.isMacroEnabled ? BST_CHECKED : BST_UNCHECKED);
    refreshMacroList();
}

void SettingsDialog::saveValuesFromUI() {
    auto& s = AppSettings::instance();

    s.isEnabled = (IsDlgButtonChecked(m_hWnd, ID_CHK_ENABLED) == BST_CHECKED);
    s.launchAtLogin = (IsDlgButtonChecked(m_hWnd, ID_CHK_STARTUP) == BST_CHECKED);

    if (IsDlgButtonChecked(m_hWnd, ID_RAD_CTRL_SPACE) == BST_CHECKED) s.shortcutOption = ShortcutOption::CtrlSpace;
    else if (IsDlgButtonChecked(m_hWnd, ID_RAD_ALT_Z) == BST_CHECKED) s.shortcutOption = ShortcutOption::AltZ;
    else if (IsDlgButtonChecked(m_hWnd, ID_RAD_CTRL_SHIFT) == BST_CHECKED) s.shortcutOption = ShortcutOption::CtrlShift;

    if (IsDlgButtonChecked(m_hWnd, ID_RAD_TELEX) == BST_CHECKED) s.inputMethod = InputMethod::Telex;
    else if (IsDlgButtonChecked(m_hWnd, ID_RAD_STELEX) == BST_CHECKED) s.inputMethod = InputMethod::SimpleTelex;
    else if (IsDlgButtonChecked(m_hWnd, ID_RAD_VNI) == BST_CHECKED) s.inputMethod = InputMethod::VNI;
    else if (IsDlgButtonChecked(m_hWnd, ID_RAD_VIQR) == BST_CHECKED) s.inputMethod = InputMethod::VIQR;

    if (IsDlgButtonChecked(m_hWnd, ID_RAD_TONE_MODERN) == BST_CHECKED) s.toneStyle = ToneStyle::Modern;
    else if (IsDlgButtonChecked(m_hWnd, ID_RAD_TONE_CLASSIC) == BST_CHECKED) s.toneStyle = ToneStyle::Classic;

    s.isSpellingCheckEnabled = (IsDlgButtonChecked(m_hWnd, ID_CHK_SPELLING) == BST_CHECKED);
    s.wAtWordStartAsW = (IsDlgButtonChecked(m_hWnd, ID_CHK_W_START) == BST_CHECKED);
    s.fixBrowserSuggestions = (IsDlgButtonChecked(m_hWnd, ID_CHK_FIX_BROWSER) == BST_CHECKED);
    s.isMacroEnabled = (IsDlgButtonChecked(m_hWnd, ID_CHK_MACRO_ENABLED) == BST_CHECKED);

    s.save();
}

void SettingsDialog::refreshMacroList() {
    HWND hList = GetDlgItem(m_hWnd, ID_LIST_MACROS);
    ListView_DeleteAllItems(hList);

    auto& macros = AppSettings::instance().macroItems;
    for (size_t i = 0; i < macros.size(); ++i) {
        LVITEMW lvi = { 0 };
        lvi.mask = LVIF_TEXT;
        lvi.iItem = static_cast<int>(i);
        lvi.pszText = (LPWSTR)macros[i].shortcut.c_str();
        ListView_InsertItem(hList, &lvi);
        ListView_SetItemText(hList, static_cast<int>(i), 1, (LPWSTR)macros[i].replacement.c_str());
    }
}

LRESULT SettingsDialog::handleMessage(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_NOTIFY: {
        NMHDR* pnm = (NMHDR*)lParam;
        if (pnm->idFrom == ID_TAB_CONTROL && pnm->code == TCN_SELCHANGE) {
            int selectedTab = TabCtrl_GetCurSel(m_hTab);
            updateTabVisibility(selectedTab);
        }
        break;
    }

    case WM_COMMAND: {
        int id = LOWORD(wParam);
        if (id == ID_BTN_CLOSE) {
            saveValuesFromUI();
            hide();
        } else if (id == ID_BTN_MACRO_ADD) {
            wchar_t szShort[128] = { 0 };
            wchar_t szRepl[256] = { 0 };
            GetDlgItemTextW(hWnd, ID_EDT_SHORTCUT, szShort, 128);
            GetDlgItemTextW(hWnd, ID_EDT_REPLACEMENT, szRepl, 256);
            if (wcslen(szShort) > 0 && wcslen(szRepl) > 0) {
                AppSettings::instance().macroItems.push_back({ szShort, szRepl });
                AppSettings::instance().save();
                refreshMacroList();
                SetDlgItemTextW(hWnd, ID_EDT_SHORTCUT, L"");
                SetDlgItemTextW(hWnd, ID_EDT_REPLACEMENT, L"");
            }
        } else if (id == ID_BTN_MACRO_DEL) {
            HWND hList = GetDlgItem(hWnd, ID_LIST_MACROS);
            int sel = ListView_GetNextItem(hList, -1, LVNI_SELECTED);
            if (sel >= 0 && sel < static_cast<int>(AppSettings::instance().macroItems.size())) {
                AppSettings::instance().macroItems.erase(AppSettings::instance().macroItems.begin() + sel);
                AppSettings::instance().save();
                refreshMacroList();
            }
        }
        break;
    }

    case WM_PAINT: {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hWnd, &ps);
        if (m_currentTab == 3) { // About Tab
            SetBkMode(hdc, TRANSPARENT);
            HFONT hTitleFont = CreateFontW(
                -20, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE,
                DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_SWISS, L"Segoe UI"
            );
            HFONT hOldFont = (HFONT)SelectObject(hdc, hTitleFont);
            const wchar_t* title = L"MoriKey cho Windows";
            TextOutW(hdc, 50, 55, title, (int)wcslen(title));

            SelectObject(hdc, (HFONT)GetStockObject(DEFAULT_GUI_FONT));
            DeleteObject(hTitleFont);

            auto drawLine = [&](int x, int y, const wchar_t* text) {
                TextOutW(hdc, x, y, text, (int)wcslen(text));
            };

            drawLine(50, 90,  L"Phiên bản: 1.0.0 (Native C++ Win32 API)");
            drawLine(50, 115, L"Tác giả: Bùi Văn Lợi");
            drawLine(50, 140, L"Địa chỉ: Kim Bôi - Hòa Bình");
            drawLine(50, 165, L"Email: buihuytran.com@gmail.com");
            drawLine(50, 190, L"GitHub: https://github.com/buihuytran");
            drawLine(50, 220, L"Bộ gõ tiếng Việt siêu nhẹ, độc lập, không cần runtime.");
            drawLine(50, 245, L"Hỗ trợ: Telex, Simple Telex, VNI, VIQR.");
            drawLine(50, 270, L"Tính năng: Khôi phục tiếng Anh thông minh, Macro gõ tắt.");
        }
        EndPaint(hWnd, &ps);
        break;
    }

    case WM_CLOSE:
        saveValuesFromUI();
        hide();
        return 0;
    }

    return DefWindowProcW(hWnd, msg, wParam, lParam);
}

