#pragma once

#include <string>
#include <unordered_set>

class EnglishDictionary {
public:
    static bool isCommonEnglishWord(const std::wstring& word);
    static const std::unordered_set<std::wstring>& getCommonWords();
};

