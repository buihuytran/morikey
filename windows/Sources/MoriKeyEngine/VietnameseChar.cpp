#include "VietnameseChar.h"

static const std::unordered_set<wchar_t> s_vowels = {
    L'a', L'ă', L'â', L'e', L'ê', L'i', L'o', L'ô', L'ơ', L'u', L'ư', L'y',
    L'A', L'Ă', L'Â', L'E', L'Ê', L'I', L'O', L'Ô', L'Ơ', L'U', L'Ư', L'Y',
    // With accents:
    L'á', L'à', L'ả', L'ã', L'ạ',
    L'ắ', L'ằ', L'ẳ', L'ẵ', L'ặ',
    L'ấ', L'ầ', L'ẩ', L'ẫ', L'ậ',
    L'é', L'è', L'ẻ', L'ẽ', L'ẹ',
    L'ế', L'ề', L'ể', L'ễ', L'ệ',
    L'í', L'ì', L'ỉ', L'ĩ', L'ị',
    L'ó', L'ò', L'ỏ', L'õ', L'ọ',
    L'ố', L'ồ', L'ổ', L'ỗ', L'ộ',
    L'ớ', L'ờ', L'ở', L'ỡ', L'ợ',
    L'ú', L'ù', L'ủ', L'ũ', L'ụ',
    L'ứ', L'ừ', L'ử', L'ữ', L'ự',
    L'ý', L'ỳ', L'ỷ', L'ỹ', L'ỵ',
    L'Á', L'À', L'Ả', L'Ã', L'Ạ',
    L'Ắ', L'Ằ', L'Ẳ', L'Ẵ', L'Ặ',
    L'Ấ', L'Ầ', L'Ẩ', L'Ẫ', L'Ậ',
    L'É', L'È', L'Ẻ', L'Ẽ', L'Ẹ',
    L'Ế', L'Ề', L'Ể', L'Ễ', L'Ệ',
    L'Í', L'Ì', L'Ỉ', L'Ĩ', L'Ị',
    L'Ó', L'Ò', L'Ỏ', L'Õ', L'Ọ',
    L'Ố', L'Ồ', L'Ổ', L'Ỗ', L'Ộ',
    L'Ớ', L'Ờ', L'Ở', L'Ỡ', L'Ợ',
    L'Ú', L'Ù', L'Ủ', L'Ũ', L'Ụ',
    L'Ứ', L'Ừ', L'Ử', L'Ữ', L'Ự',
    L'Ý', L'Ỳ', L'Ỷ', L'Ỹ', L'Ỵ'
};

static const std::unordered_map<wchar_t, std::vector<wchar_t>> s_toneMap = {
    { L'a', { L'a', L'á', L'à', L'ả', L'ã', L'ạ' } },
    { L'ă', { L'ă', L'ắ', L'ằ', L'ẳ', L'ẵ', L'ặ' } },
    { L'â', { L'â', L'ấ', L'ầ', L'ẩ', L'ẫ', L'ậ' } },
    { L'e', { L'e', L'é', L'è', L'ẻ', L'ẽ', L'ẹ' } },
    { L'ê', { L'ê', L'ế', L'ề', L'ể', L'ễ', L'ệ' } },
    { L'i', { L'i', L'í', L'ì', L'ỉ', L'ĩ', L'ị' } },
    { L'o', { L'o', L'ó', L'ò', L'ỏ', L'õ', L'ọ' } },
    { L'ô', { L'ô', L'ố', L'ồ', L'ổ', L'ỗ', L'ộ' } },
    { L'ơ', { L'ơ', L'ớ', L'ờ', L'ở', L'ỡ', L'ợ' } },
    { L'u', { L'u', L'ú', L'ù', L'ủ', L'ũ', L'ụ' } },
    { L'ư', { L'ư', L'ứ', L'ừ', L'ử', L'ữ', L'ự' } },
    { L'y', { L'y', L'ý', L'ỳ', L'ỷ', L'ỹ', L'ỵ' } },

    { L'A', { L'A', L'Á', L'À', L'Ả', L'Ã', L'Ạ' } },
    { L'Ă', { L'Ă', L'Ắ', L'Ằ', L'Ẳ', L'Ẵ', L'Ặ' } },
    { L'Â', { L'Â', L'Ấ', L'Ầ', L'Ẩ', L'Ẫ', L'Ậ' } },
    { L'E', { L'E', L'É', L'È', L'Ẻ', L'Ẽ', L'Ẹ' } },
    { L'Ê', { L'Ê', L'Ế', L'Ề', L'Ể', L'Ễ', L'Ệ' } },
    { L'I', { L'I', L'Í', L'Ì', L'Ỉ', L'Ĩ', L'Ị' } },
    { L'O', { L'O', L'Ó', L'Ò', L'Ỏ', L'Õ', L'Ọ' } },
    { L'Ô', { L'Ô', L'Ố', L'Ồ', L'Ổ', L'Ỗ', L'Ộ' } },
    { L'Ơ', { L'Ơ', L'Ớ', L'Ờ', L'Ở', L'Ỡ', L'Ợ' } },
    { L'U', { L'U', L'Ú', L'Ù', L'Ủ', L'Ũ', L'Ụ' } },
    { L'Ư', { L'Ư', L'Ứ', L'Ừ', L'Ử', L'Ữ', L'Ự' } },
    { L'Y', { L'Y', L'Ý', L'Ỳ', L'Ỷ', L'Ỹ', L'Ỵ' } }
};

static std::unordered_map<wchar_t, VietnameseChar::ToneInfo> initCharToToneInfo() {
    std::unordered_map<wchar_t, VietnameseChar::ToneInfo> map;
    for (const auto& pair : s_toneMap) {
        wchar_t base = pair.first;
        const auto& list = pair.second;
        for (size_t idx = 0; idx < list.size(); ++idx) {
            map[list[idx]] = { base, static_cast<Tone>(idx) };
        }
    }
    return map;
}

const std::unordered_set<wchar_t>& VietnameseChar::getVowels() {
    return s_vowels;
}

const std::unordered_map<wchar_t, std::vector<wchar_t>>& VietnameseChar::getToneMap() {
    return s_toneMap;
}

const std::unordered_map<wchar_t, VietnameseChar::ToneInfo>& VietnameseChar::getCharToToneInfo() {
    static const auto s_map = initCharToToneInfo();
    return s_map;
}

bool VietnameseChar::isVowel(wchar_t ch) {
    return s_vowels.find(ch) != s_vowels.end();
}

Tone VietnameseChar::getTone(wchar_t ch) {
    const auto& map = getCharToToneInfo();
    auto it = map.find(ch);
    if (it != map.end()) {
        return it->second.tone;
    }
    return Tone::None;
}

wchar_t VietnameseChar::removeTone(wchar_t ch) {
    const auto& map = getCharToToneInfo();
    auto it = map.find(ch);
    if (it != map.end()) {
        return it->second.base;
    }
    return ch;
}

wchar_t VietnameseChar::applyTone(wchar_t baseWithDiacritic, Tone tone) {
    auto it = s_toneMap.find(baseWithDiacritic);
    if (it != s_toneMap.end()) {
        size_t idx = static_cast<size_t>(tone);
        if (idx < it->second.size()) {
            return it->second[idx];
        }
    }
    return baseWithDiacritic;
}

static const std::unordered_map<wchar_t, wchar_t>& getUpperToLowerMap() {
    static const std::unordered_map<wchar_t, wchar_t> map = {
        { L'á', L'Á' }, { L'à', L'À' }, { L'ả', L'Ả' }, { L'ã', L'Ã' }, { L'ạ', L'Ạ' },
        { L'ă', L'Ă' }, { L'ắ', L'Ắ' }, { L'ằ', L'Ằ' }, { L'ẳ', L'Ẳ' }, { L'ẵ', L'Ẵ' }, { L'ặ', L'Ặ' },
        { L'â', L'Â' }, { L'ấ', L'Ấ' }, { L'ầ', L'Ầ' }, { L'ẩ', L'Ẩ' }, { L'ẫ', L'Ẫ' }, { L'ậ', L'Ậ' },
        { L'é', L'É' }, { L'è', L'È' }, { L'ẻ', L'Ẻ' }, { L'ẽ', L'Ẽ' }, { L'ẹ', L'Ẹ' },
        { L'ê', L'Ê' }, { L'ế', L'Ế' }, { L'ề', L'Ề' }, { L'ể', L'Ể' }, { L'ễ', L'Ễ' }, { L'ệ', L'Ệ' },
        { L'í', L'Í' }, { L'ì', L'Ì' }, { L'ỉ', L'Ỉ' }, { L'ĩ', L'Ĩ' }, { L'ị', L'Ị' },
        { L'ó', L'Ó' }, { L'ò', L'Ò' }, { L'ỏ', L'Ỏ' }, { L'õ', L'Õ' }, { L'ọ', L'Ọ' },
        { L'ô', L'Ô' }, { L'ố', L'Ố' }, { L'ồ', L'Ồ' }, { L'ổ', L'Ổ' }, { L'ỗ', L'Ỗ' }, { L'ộ', L'Ộ' },
        { L'ơ', L'Ơ' }, { L'ớ', L'Ớ' }, { L'ờ', L'Ờ' }, { L'ở', L'Ở' }, { L'ỡ', L'Ỡ' }, { L'ợ', L'Ợ' },
        { L'ú', L'Ú' }, { L'ù', L'Ù' }, { L'ủ', L'Ủ' }, { L'ũ', L'Ũ' }, { L'ụ', L'Ụ' },
        { L'ư', L'Ư' }, { L'ứ', L'Ứ' }, { L'ừ', L'Ừ' }, { L'ử', L'Ử' }, { L'ữ', L'Ữ' }, { L'ự', L'Ự' },
        { L'ý', L'Ý' }, { L'ỳ', L'Ỳ' }, { L'ỷ', L'Ỷ' }, { L'ỹ', L'Ỹ' }, { L'ỵ', L'Ỵ' },
        { L'đ', L'Đ' }
    };
    return map;
}

static const std::unordered_map<wchar_t, wchar_t>& getLowerToUpperMap() {
    static const auto map = []() {
        std::unordered_map<wchar_t, wchar_t> m;
        for (const auto& p : getUpperToLowerMap()) {
            m[p.second] = p.first;
        }
        return m;
    }();
    return map;
}

wchar_t VietnameseChar::toUpper(wchar_t ch) {
    if (ch >= L'a' && ch <= L'z') {
        return ch - (L'a' - L'A');
    }
    const auto& map = getUpperToLowerMap();
    auto it = map.find(ch);
    if (it != map.end()) {
        return it->second;
    }
    return ch;
}

wchar_t VietnameseChar::toLower(wchar_t ch) {
    if (ch >= L'A' && ch <= L'Z') {
        return ch + (L'a' - L'A');
    }
    const auto& map = getLowerToUpperMap();
    auto it = map.find(ch);
    if (it != map.end()) {
        return it->second;
    }
    return ch;
}

std::wstring VietnameseChar::toUpper(const std::wstring& str) {
    std::wstring result = str;
    for (auto& c : result) {
        c = toUpper(c);
    }
    return result;
}

std::wstring VietnameseChar::toLower(const std::wstring& str) {
    std::wstring result = str;
    for (auto& c : result) {
        c = toLower(c);
    }
    return result;
}
