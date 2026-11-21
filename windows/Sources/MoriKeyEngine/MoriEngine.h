#pragma once

#include "InputMethod.h"
#include "MacroEngine.h"
#include <string>

struct TypingAction {
    enum class Type {
        PassThrough,
        Replace
    };

    Type type;
    int deleteCount;
    std::wstring text;

    static TypingAction passThrough() {
        return { Type::PassThrough, 0, L"" };
    }

    static TypingAction replace(int delCount, std::wstring newText) {
        return { Type::Replace, delCount, std::move(newText) };
    }

    bool operator==(const TypingAction& other) const {
        return type == other.type && deleteCount == other.deleteCount && text == other.text;
    }
};

class MoriEngine {
public:
    InputMethod inputMethod;
    ToneStyle toneStyle;
    bool isEnabled;
    bool isSpellingCheckEnabled;
    bool wAtWordStartAsW;
    MacroEngine macroEngine;

    MoriEngine(
        InputMethod method = InputMethod::Telex,
        ToneStyle style = ToneStyle::Modern,
        bool enabled = true,
        bool spellingCheck = true,
        bool wAtStart = true
    );

    void reset();
    void handleBackspace();
    TypingAction process(wchar_t ch);

    const std::wstring& getCurrentWord() const { return m_currentWord; }
    const std::wstring& getRawWord() const { return m_rawWord; }

private:
    std::wstring m_currentWord;
    std::wstring m_rawWord;

    bool isDelimiter(wchar_t ch) const;
};

