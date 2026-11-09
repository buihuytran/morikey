import Foundation

public struct MacroItem: Identifiable, Codable, Equatable {
    public var id: UUID
    public var shortcut: String
    public var replacement: String

    public init(id: UUID = UUID(), shortcut: String, replacement: String) {
        self.id = id
        self.shortcut = shortcut
        self.replacement = replacement
    }
}

public final class MacroEngine {
    public var isEnabled: Bool = true
    public var macros: [String: String] = [
        "vn": "Việt Nam",
        "hn": "Hà Nội",
        "hcm": "Hồ Chí Minh",
        "dc": "được",
        "ko": "không",
        "ng": "người",
        "k": "không",
        "cg": "con gái",
        "ct": "chúng ta"
    ]

    public init(isEnabled: Bool = true, macros: [String: String]? = nil) {
        self.isEnabled = isEnabled
        if let macros = macros {
            self.macros = macros
        }
    }

    /// Looks up replacement for a word with case-preservation support
    public func lookup(word: String) -> String? {
        guard isEnabled, !word.isEmpty else { return nil }
        let lower = word.lowercased()
        guard let baseReplacement = macros[lower] else { return nil }

        // All uppercase: VN -> VIỆT NAM
        if word == word.uppercased() && word.count > 1 {
            return baseReplacement.uppercased()
        }

        // Capitalized: Vn -> Việt Nam
        if let first = word.first, first.isUppercase {
            return baseReplacement.prefix(1).uppercased() + baseReplacement.dropFirst()
        }

        return baseReplacement
    }
}
