#pragma once

#include <string>
#include <vector>
#include <unordered_set>

class SpellingChecker {
public:
    static bool hasInvalidInitialCluster(const std::wstring& word);
    static bool hasForeignInitialOrChar(const std::wstring& word);
    static bool containsInvalidCluster(const std::wstring& word);
    static bool isPolysyllabicWord(const std::wstring& word);
    static bool isNonVietnameseWord(const std::wstring& word);
    static bool hasInvalidCoda(const std::wstring& word);
    static bool isValidVietnameseSyllable(const std::wstring& word);
    static bool isProtectedVietnameseWord(const std::wstring& word);
    static bool isLikelyEnglishWord(const std::wstring& currentWord, const std::wstring& rawWord);

    static const std::vector<std::wstring>& getInvalidClusters();
};

