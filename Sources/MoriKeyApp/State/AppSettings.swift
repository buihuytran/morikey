import SwiftUI
import MoriKeyEngine

public enum ShortcutOption: String, CaseIterable, Identifiable, Codable {
    case controlSpace = "Control + Space (⌃␣)"
    case optionSpace = "Option + Space (⌥␣)"
    case shiftSpace = "Shift + Space (⇧␣)"

    public var id: String { rawValue }
}

public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    private enum Keys {
        static let isEnabled = "mori_is_enabled"
        static let inputMethod = "mori_input_method"
        static let toneStyle = "mori_tone_style"
        static let isSpellingCheckEnabled = "mori_spelling_check"
        static let isMacroEnabled = "mori_macro_enabled"
        static let macroItems = "mori_macro_items_json"
        static let shortcutOption = "mori_shortcut_option"
    }

    @Published public var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Keys.isEnabled)
            MoriEngineManager.shared.engine.isEnabled = isEnabled
            NotificationCenter.default.post(name: .moriSettingsChanged, object: nil)
        }
    }

    @Published public var inputMethod: InputMethod {
        didSet {
            UserDefaults.standard.set(inputMethod.rawValue, forKey: Keys.inputMethod)
            MoriEngineManager.shared.engine.inputMethod = inputMethod
        }
    }

    @Published public var toneStyle: ToneStyle {
        didSet {
            UserDefaults.standard.set(toneStyle.rawValue, forKey: Keys.toneStyle)
            MoriEngineManager.shared.engine.toneStyle = toneStyle
        }
    }

    @Published public var isSpellingCheckEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSpellingCheckEnabled, forKey: Keys.isSpellingCheckEnabled)
            MoriEngineManager.shared.engine.isSpellingCheckEnabled = isSpellingCheckEnabled
        }
    }

    @Published public var isMacroEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isMacroEnabled, forKey: Keys.isMacroEnabled)
            MoriEngineManager.shared.engine.macroEngine.isEnabled = isMacroEnabled
        }
    }

    @Published public var shortcutOption: ShortcutOption {
        didSet {
            UserDefaults.standard.set(shortcutOption.rawValue, forKey: Keys.shortcutOption)
        }
    }

    @Published public var macroItems: [MacroItem] {
        didSet {
            saveMacroItems()
            syncMacroEngine()
        }
    }

    @Published public var launchAtLogin: Bool {
        didSet {
            LaunchAtLoginHelper.isEnabled = launchAtLogin
        }
    }

    private init() {
        let isEnabled = UserDefaults.standard.object(forKey: Keys.isEnabled) as? Bool ?? true
        let methodRaw = UserDefaults.standard.string(forKey: Keys.inputMethod) ?? InputMethod.telex.rawValue
        let inputMethod = InputMethod(rawValue: methodRaw) ?? .telex
        let toneRaw = UserDefaults.standard.string(forKey: Keys.toneStyle) ?? ToneStyle.modern.rawValue
        let toneStyle = ToneStyle(rawValue: toneRaw) ?? .modern
        let spelling = UserDefaults.standard.object(forKey: Keys.isSpellingCheckEnabled) as? Bool ?? true
        let macroOn = UserDefaults.standard.object(forKey: Keys.isMacroEnabled) as? Bool ?? true
        let shortcutRaw = UserDefaults.standard.string(forKey: Keys.shortcutOption) ?? ShortcutOption.controlSpace.rawValue
        let shortcut = ShortcutOption(rawValue: shortcutRaw) ?? .controlSpace

        self.isEnabled = isEnabled
        self.inputMethod = inputMethod
        self.toneStyle = toneStyle
        self.isSpellingCheckEnabled = spelling
        self.isMacroEnabled = macroOn
        self.shortcutOption = shortcut
        self.launchAtLogin = LaunchAtLoginHelper.isEnabled

        // Load Macro Items from UserDefaults or default
        if let data = UserDefaults.standard.data(forKey: Keys.macroItems),
           let decoded = try? JSONDecoder().decode([MacroItem].self, from: data) {
            self.macroItems = decoded
        } else {
            self.macroItems = [
                MacroItem(shortcut: "vn", replacement: "Việt Nam"),
                MacroItem(shortcut: "hn", replacement: "Hà Nội"),
                MacroItem(shortcut: "hcm", replacement: "Hồ Chí Minh"),
                MacroItem(shortcut: "dc", replacement: "được"),
                MacroItem(shortcut: "ko", replacement: "không"),
                MacroItem(shortcut: "ng", replacement: "người"),
                MacroItem(shortcut: "k", replacement: "không")
            ]
        }

        // Synchronize with the underlying engine immediately
        MoriEngineManager.shared.engine.isEnabled = isEnabled
        MoriEngineManager.shared.engine.inputMethod = inputMethod
        MoriEngineManager.shared.engine.toneStyle = toneStyle
        MoriEngineManager.shared.engine.isSpellingCheckEnabled = spelling
        MoriEngineManager.shared.engine.macroEngine.isEnabled = macroOn
        syncMacroEngine()
    }

    private func saveMacroItems() {
        if let data = try? JSONEncoder().encode(macroItems) {
            UserDefaults.standard.set(data, forKey: Keys.macroItems)
        }
    }

    private func syncMacroEngine() {
        var dict: [String: String] = [:]
        for item in macroItems {
            if !item.shortcut.isEmpty && !item.replacement.isEmpty {
                dict[item.shortcut.lowercased()] = item.replacement
            }
        }
        MoriEngineManager.shared.engine.macroEngine.macros = dict
    }

    public func addMacro(shortcut: String, replacement: String) {
        let cleanKey = shortcut.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanVal = replacement.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty && !cleanVal.isEmpty else { return }

        // Remove if key already exists, then prepend
        macroItems.removeAll { $0.shortcut.lowercased() == cleanKey.lowercased() }
        macroItems.insert(MacroItem(shortcut: cleanKey, replacement: cleanVal), at: 0)
    }

    public func removeMacro(id: UUID) {
        macroItems.removeAll { $0.id == id }
    }

    public func toggleVietnamese() {
        isEnabled.toggle()
    }
}

extension Notification.Name {
    public static let moriSettingsChanged = Notification.Name("moriSettingsChanged")
}
