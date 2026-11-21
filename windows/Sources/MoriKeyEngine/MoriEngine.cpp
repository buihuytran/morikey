#include "MoriEngine.h"
#include "VietnameseChar.h"
#include "DiacriticTransform.h"
#include "VNIRules.h"
#include "VIQRTransform.h"
#include "ToneRule.h"
#include "SpellingChecker.h"
#include "EnglishDictionary.h"
#include <cwctype>

MoriEngine::MoriEngine(
    InputMethod method,
    ToneStyle style,
    bool enabled,
    bool spellingCheck,
    bool wAtStart
) : inputMethod(method),
    toneStyle(style),
    isEnabled(enabled),
    isSpellingCheckEnabled(spellingCheck),
    wAtWordStartAsW(wAtStart)
{
}

void MoriEngine::reset() {
    m_currentWord.clear();
    m_rawWord.clear();
}

void MoriEngine::handleBackspace() {
    if (!m_currentWord.empty()) {
        m_currentWord.pop_back();
    }
    if (!m_rawWord.empty()) {
        m_rawWord.pop_back();
    }
}

bool MoriEngine::isDelimiter(wchar_t ch) const {
    if (std::iswspace(ch)) {
        return true;
    }

    switch (inputMethod) {
    case InputMethod::Telex:
    case InputMethod::SimpleTelex:
        if (ch == L'[' || ch == L']' || ch == L'{' || ch == L'}') {
            return false;
        }
        return std::iswpunct(ch);

    case InputMethod::VNI:
        if (std::iswdigit(ch)) {
            return false;
        }
        return std::iswpunct(ch);

    case InputMethod::VIQR: {
        static const std::wstring viqrKeys = L"'`?~.^+-0*(";
        if (viqrKeys.find(ch) != std::wstring::npos) {
            return false;
        }
        return std::iswpunct(ch);
    }
    }
    return false;
}

TypingAction MoriEngine::process(wchar_t ch) {
    guard_check:
    if (!isEnabled) {
        reset();
        return TypingAction::passThrough();
    }

    if (isDelimiter(ch)) {
        // 1. Macro expansion
        if (macroEngine.isEnabled) {
            auto macroReplacement = macroEngine.lookup(m_currentWord);
            if (macroReplacement.has_value()) {
                int deleteCount = static_cast<int>(m_currentWord.length());
                reset();
                return TypingAction::replace(deleteCount, macroReplacement.value() + ch);
            }
        }

        // 2. Smart English Auto-Restore on word boundary
        if (isSpellingCheckEnabled && m_currentWord != m_rawWord && !m_currentWord.empty()) {
            if (SpellingChecker::isLikelyEnglishWord(m_currentWord, m_rawWord)) {
                int deleteCount = static_cast<int>(m_currentWord.length());
                std::wstring restored = m_rawWord;
                reset();
                return TypingAction::replace(deleteCount, restored + ch);
            }
        }

        reset();
        return TypingAction::passThrough();
    }

    m_rawWord.push_back(ch);

    switch (inputMethod) {
    case InputMethod::Telex:
    case InputMethod::SimpleTelex: {
        // 0. Foreign word bypass
        if (isSpellingCheckEnabled) {
            bool isForeignInitial = SpellingChecker::hasInvalidInitialCluster(m_rawWord) ||
                                    SpellingChecker::hasForeignInitialOrChar(m_rawWord);
            bool isAlreadyPolysyllabic = !m_currentWord.empty() && SpellingChecker::isPolysyllabicWord(m_currentWord);
            if (isForeignInitial || isAlreadyPolysyllabic) {
                m_currentWord.push_back(ch);
                return TypingAction::passThrough();
            }
        }

        // 1. Try diacritics
        auto diacriticResult = DiacriticTransform::tryTransformVowel(
            m_currentWord,
            m_rawWord,
            ch,
            inputMethod,
            wAtWordStartAsW
        );
        if (diacriticResult.has_value()) {
            int deleteCount = static_cast<int>(m_currentWord.length());
            m_currentWord = diacriticResult->text;
            if (diacriticResult->isUndo) {
                m_rawWord = diacriticResult->text;
            }
            return TypingAction::replace(deleteCount, diacriticResult->text);
        }

        // 2. Try tones
        auto toneResult = DiacriticTransform::tryApplyTone(
            m_currentWord,
            ch,
            toneStyle
        );
        if (toneResult.has_value()) {
            int deleteCount = static_cast<int>(m_currentWord.length());
            m_currentWord = toneResult->text;
            if (toneResult->isUndo) {
                m_rawWord = toneResult->text;
            }
            return TypingAction::replace(deleteCount, toneResult->text);
        }

        // 3. Normal character typing
        if (std::iswalpha(ch)) {
            std::wstring directCandidate = m_currentWord + ch;
            std::wstring candidate = ToneRule::repositionTone(directCandidate, toneStyle);

            // Real-time check: if appending this letter forms an English word or non-Vietnamese structure:
            if (isSpellingCheckEnabled && directCandidate != m_rawWord) {
                bool shouldRestore = false;

                if (SpellingChecker::hasInvalidCoda(directCandidate)) {
                    shouldRestore = true;
                } else if (SpellingChecker::isPolysyllabicWord(directCandidate)) {
                    shouldRestore = true;
                } else if (EnglishDictionary::isCommonEnglishWord(m_rawWord)) {
                    if (!SpellingChecker::isProtectedVietnameseWord(directCandidate)) {
                        shouldRestore = true;
                    }
                }

                if (shouldRestore) {
                    int deleteCount = static_cast<int>(m_currentWord.length());
                    m_currentWord = m_rawWord;
                    return TypingAction::replace(deleteCount, m_rawWord);
                }
            }

            if (candidate != directCandidate) {
                int deleteCount = static_cast<int>(m_currentWord.length());
                m_currentWord = candidate;
                return TypingAction::replace(deleteCount, candidate);
            }

            m_currentWord.push_back(ch);
            return TypingAction::passThrough();
        } else {
            reset();
            return TypingAction::passThrough();
        }
    }

    case InputMethod::VNI: {
        if (std::iswdigit(ch)) {
            auto transformed = VNITransform::tryTransformVNI(
                m_currentWord,
                ch,
                toneStyle
            );
            if (transformed.has_value()) {
                int deleteCount = static_cast<int>(m_currentWord.length());
                m_currentWord = transformed.value();
                return TypingAction::replace(deleteCount, transformed.value());
            } else {
                m_currentWord.push_back(ch);
                return TypingAction::passThrough();
            }
        } else if (std::iswalpha(ch)) {
            m_currentWord.push_back(ch);
            return TypingAction::passThrough();
        } else {
            reset();
            return TypingAction::passThrough();
        }
    }

    case InputMethod::VIQR: {
        static const std::wstring viqrSpecialKeys = L"'`?~.^+-0*(-";
        if (viqrSpecialKeys.find(ch) != std::wstring::npos || std::iswalpha(ch)) {
            auto transformed = VIQRTransform::tryTransformVIQR(
                m_currentWord,
                ch,
                toneStyle
            );
            if (transformed.has_value()) {
                int deleteCount = static_cast<int>(m_currentWord.length());
                m_currentWord = transformed.value();
                return TypingAction::replace(deleteCount, transformed.value());
            }
            m_currentWord.push_back(ch);
            return TypingAction::passThrough();
        } else {
            reset();
            return TypingAction::passThrough();
        }
    }
    }

    return TypingAction::passThrough();
}
