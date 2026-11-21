#pragma once

#include <windows.h>
#include <string>

// ASCII 'MORI' = 0x4D4F5249
constexpr ULONG_PTR MORI_EVENT_TAG = 0x4D4F5249;

class KeySimulator {
public:
    /// Replaces `deleteCount` characters on screen with `text`.
    /// When `fixBrowserAutocomplete` is true, sends VK_DELETE first to dismiss browser inline autocomplete.
    static void replaceText(int deleteCount, const std::wstring& text, bool fixBrowserAutocomplete = false);

    /// Sends `count` virtual backspaces to delete text on screen
    static void sendBackspaces(int count);

    /// Sends a Unicode string through simulated keyboard inputs
    static void sendString(const std::wstring& text);
};

