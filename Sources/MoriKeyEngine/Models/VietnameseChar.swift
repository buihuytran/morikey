import Foundation

public struct VietnameseChar {
    public static let vowels: Set<Character> = [
        "a", "ă", "â", "e", "ê", "i", "o", "ô", "ơ", "u", "ư", "y",
        "A", "Ă", "Â", "E", "Ê", "I", "O", "Ô", "Ơ", "U", "Ư", "Y",
        // With accents:
        "á", "à", "ả", "ã", "ạ",
        "ắ", "ằ", "ẳ", "ẵ", "ặ",
        "ấ", "ầ", "ẩ", "ẫ", "ậ",
        "é", "è", "ẻ", "ẽ", "ẹ",
        "ế", "ề", "ể", "ễ", "ệ",
        "í", "ì", "ỉ", "ĩ", "ị",
        "ó", "ò", "ỏ", "õ", "ọ",
        "ố", "ồ", "ổ", "ỗ", "ộ",
        "ớ", "ờ", "ở", "ỡ", "ợ",
        "ú", "ù", "ủ", "ũ", "ụ",
        "ứ", "ừ", "ử", "ữ", "ự",
        "ý", "ỳ", "ỷ", "ỹ", "ỵ",
        "Á", "À", "Ả", "Ã", "Ạ",
        "Ắ", "Ằ", "Ẳ", "Ẵ", "Ặ",
        "Ấ", "Ầ", "Ẩ", "Ẫ", "Ậ",
        "É", "È", "Ẻ", "Ẽ", "Ẹ",
        "Ế", "Ề", "Ể", "Ễ", "Ệ",
        "Í", "Ì", "Ỉ", "Ĩ", "Ị",
        "Ó", "Ò", "Ỏ", "Õ", "Ọ",
        "Ố", "Ồ", "Ổ", "Ỗ", "Ộ",
        "Ớ", "Ờ", "Ở", "Ỡ", "Ợ",
        "Ú", "Ù", "Ủ", "Ũ", "Ụ",
        "Ứ", "Ừ", "Ử", "Ữ", "Ự",
        "Ý", "Ỳ", "Ỷ", "Ỹ", "Ỵ"
    ]

    // Base vowels matrix: [BaseVowel][Tone (0...5)]
    // 0: none, 1: acute (sắc), 2: grave (huyền), 3: hook (hỏi), 4: tilde (ngã), 5: heavy (nặng)
    public static let toneMap: [Character: [Character]] = [
        "a": ["a", "á", "à", "ả", "ã", "ạ"],
        "ă": ["ă", "ắ", "ằ", "ẳ", "ẵ", "ặ"],
        "â": ["â", "ấ", "ầ", "ẩ", "ẫ", "ậ"],
        "e": ["e", "é", "è", "ẻ", "ẽ", "ẹ"],
        "ê": ["ê", "ế", "ề", "ể", "ễ", "ệ"],
        "i": ["i", "í", "ì", "ỉ", "ĩ", "ị"],
        "o": ["o", "ó", "ò", "ỏ", "õ", "ọ"],
        "ô": ["ô", "ố", "ồ", "ổ", "ỗ", "ộ"],
        "ơ": ["ơ", "ớ", "ờ", "ở", "ỡ", "ợ"],
        "u": ["u", "ú", "ù", "ủ", "ũ", "ụ"],
        "ư": ["ư", "ứ", "ừ", "ử", "ữ", "ự"],
        "y": ["y", "ý", "ỳ", "ỷ", "ỹ", "ỵ"],

        "A": ["A", "Á", "À", "Ả", "Ã", "Ạ"],
        "Ă": ["Ă", "Ắ", "Ằ", "Ẳ", "Ẵ", "Ặ"],
        "Â": ["Â", "Ấ", "Ầ", "Ẩ", "Ẫ", "Ậ"],
        "E": ["E", "É", "È", "Ẻ", "Ẽ", "Ẹ"],
        "Ê": ["Ê", "Ế", "Ề", "Ể", "Ễ", "Ệ"],
        "I": ["I", "Í", "Ì", "Ỉ", "Ĩ", "Ị"],
        "O": ["O", "Ó", "Ò", "Ỏ", "Õ", "Ọ"],
        "Ô": ["Ô", "Ố", "Ồ", "Ổ", "Ỗ", "Ộ"],
        "Ơ": ["Ơ", "Ớ", "Ờ", "Ở", "Ỡ", "Ợ"],
        "U": ["U", "Ú", "Ù", "Ủ", "Ũ", "Ụ"],
        "Ư": ["Ư", "Ứ", "Ừ", "Ử", "Ữ", "Ự"],
        "Y": ["Y", "Ý", "Ỳ", "Ỷ", "Ỹ", "Ỵ"]
    ]

    // Inverse lookup: Character -> (Base with diacritic without tone, Tone)
    public static let charToToneInfo: [Character: (base: Character, tone: Tone)] = {
        var map: [Character: (Character, Tone)] = [:]
        for (base, list) in toneMap {
            for (idx, char) in list.enumerated() {
                let tone = Tone(rawValue: idx) ?? .none
                map[char] = (base, tone)
            }
        }
        return map
    }()

    public static func isVowel(_ char: Character) -> Bool {
        return vowels.contains(char)
    }

    public static func getTone(_ char: Character) -> Tone {
        return charToToneInfo[char]?.tone ?? .none
    }

    public static func removeTone(_ char: Character) -> Character {
        return charToToneInfo[char]?.base ?? char
    }

    public static func applyTone(_ baseWithDiacritic: Character, tone: Tone) -> Character {
        guard let list = toneMap[baseWithDiacritic] else { return baseWithDiacritic }
        return list[tone.rawValue]
    }
}

