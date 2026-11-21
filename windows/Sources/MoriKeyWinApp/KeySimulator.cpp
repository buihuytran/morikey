#include "KeySimulator.h"
#include <vector>

void KeySimulator::replaceText(int deleteCount, const std::wstring& text, bool fixBrowserAutocomplete) {
    if (deleteCount <= 0 && text.empty()) return;

    std::vector<INPUT> inputs;
    inputs.reserve((deleteCount + (fixBrowserAutocomplete ? 1 : 0) + text.length()) * 2);

    // 1. If in a browser, send VK_DELETE first to cancel/delete any inline autocomplete selection
    if (fixBrowserAutocomplete) {
        INPUT down = { 0 };
        down.type = INPUT_KEYBOARD;
        down.ki.wVk = VK_DELETE;
        down.ki.dwExtraInfo = MORI_EVENT_TAG;
        inputs.push_back(down);

        INPUT up = { 0 };
        up.type = INPUT_KEYBOARD;
        up.ki.wVk = VK_DELETE;
        up.ki.dwFlags = KEYEVENTF_KEYUP;
        up.ki.dwExtraInfo = MORI_EVENT_TAG;
        inputs.push_back(up);
    }

    // 2. Send Backspaces
    for (int i = 0; i < deleteCount; ++i) {
        INPUT down = { 0 };
        down.type = INPUT_KEYBOARD;
        down.ki.wVk = VK_BACK;
        down.ki.dwExtraInfo = MORI_EVENT_TAG;
        inputs.push_back(down);

        INPUT up = { 0 };
        up.type = INPUT_KEYBOARD;
        up.ki.wVk = VK_BACK;
        up.ki.dwFlags = KEYEVENTF_KEYUP;
        up.ki.dwExtraInfo = MORI_EVENT_TAG;
        inputs.push_back(up);
    }

    // 3. Send Unicode replacement text
    for (wchar_t ch : text) {
        INPUT down = { 0 };
        down.type = INPUT_KEYBOARD;
        down.ki.wVk = 0;
        down.ki.wScan = ch;
        down.ki.dwFlags = KEYEVENTF_UNICODE;
        down.ki.dwExtraInfo = MORI_EVENT_TAG;
        inputs.push_back(down);

        INPUT up = { 0 };
        up.type = INPUT_KEYBOARD;
        up.ki.wVk = 0;
        up.ki.wScan = ch;
        up.ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;
        up.ki.dwExtraInfo = MORI_EVENT_TAG;
        inputs.push_back(up);
    }

    if (!inputs.empty()) {
        SendInput(static_cast<UINT>(inputs.size()), inputs.data(), sizeof(INPUT));
    }
}

void KeySimulator::sendBackspaces(int count) {
    if (count <= 0) return;

    std::vector<INPUT> inputs;
    inputs.reserve(count * 2);

    for (int i = 0; i < count; ++i) {
        // Backspace down
        INPUT down = { 0 };
        down.type = INPUT_KEYBOARD;
        down.ki.wVk = VK_BACK;
        down.ki.dwFlags = 0;
        down.ki.dwExtraInfo = MORI_EVENT_TAG;
        inputs.push_back(down);

        // Backspace up
        INPUT up = { 0 };
        up.type = INPUT_KEYBOARD;
        up.ki.wVk = VK_BACK;
        up.ki.dwFlags = KEYEVENTF_KEYUP;
        up.ki.dwExtraInfo = MORI_EVENT_TAG;
        inputs.push_back(up);
    }

    SendInput(static_cast<UINT>(inputs.size()), inputs.data(), sizeof(INPUT));
}

void KeySimulator::sendString(const std::wstring& text) {
    if (text.empty()) return;

    std::vector<INPUT> inputs;
    inputs.reserve(text.length() * 2);

    for (wchar_t ch : text) {
        // Char down
        INPUT down = { 0 };
        down.type = INPUT_KEYBOARD;
        down.ki.wVk = 0;
        down.ki.wScan = ch;
        down.ki.dwFlags = KEYEVENTF_UNICODE;
        down.ki.dwExtraInfo = MORI_EVENT_TAG;
        inputs.push_back(down);

        // Char up
        INPUT up = { 0 };
        up.type = INPUT_KEYBOARD;
        up.ki.wVk = 0;
        up.ki.wScan = ch;
        up.ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;
        up.ki.dwExtraInfo = MORI_EVENT_TAG;
        inputs.push_back(up);
    }

    SendInput(static_cast<UINT>(inputs.size()), inputs.data(), sizeof(INPUT));
}

