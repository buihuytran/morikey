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
        static let wAtWordStartAsW = "mori_w_at_start_as_w"
        static let fixBrowserSuggestions = "mori_fix_browser_suggestions"
        static let isMacroEnabled = "mori_macro_enabled"
        static let macroItems = "mori_macro_items_json"
        static let shortcutOption = "mori_shortcut_option"
        static let hasConfiguredStartup = "mori_has_configured_startup"
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

    @Published public var wAtWordStartAsW: Bool {
        didSet {
            UserDefaults.standard.set(wAtWordStartAsW, forKey: Keys.wAtWordStartAsW)
            MoriEngineManager.shared.engine.wAtWordStartAsW = wAtWordStartAsW
        }
    }

    @Published public var fixBrowserSuggestions: Bool {
        didSet {
            UserDefaults.standard.set(fixBrowserSuggestions, forKey: Keys.fixBrowserSuggestions)
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
            UserDefaults.standard.set(true, forKey: Keys.hasConfiguredStartup)
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
        let wAtStart = UserDefaults.standard.object(forKey: Keys.wAtWordStartAsW) as? Bool ?? true
        let fixBrowser = UserDefaults.standard.object(forKey: Keys.fixBrowserSuggestions) as? Bool ?? true
        let macroOn = UserDefaults.standard.object(forKey: Keys.isMacroEnabled) as? Bool ?? false
        let shortcutRaw = UserDefaults.standard.string(forKey: Keys.shortcutOption) ?? ShortcutOption.controlSpace.rawValue
        let shortcut = ShortcutOption(rawValue: shortcutRaw) ?? .controlSpace

        self.isEnabled = isEnabled
        self.inputMethod = inputMethod
        self.toneStyle = toneStyle
        self.isSpellingCheckEnabled = spelling
        self.wAtWordStartAsW = wAtStart
        self.fixBrowserSuggestions = fixBrowser
        self.isMacroEnabled = macroOn
        self.shortcutOption = shortcut

        let hasConfigured = UserDefaults.standard.bool(forKey: Keys.hasConfiguredStartup)
        if !hasConfigured {
            LaunchAtLoginHelper.isEnabled = true
            UserDefaults.standard.set(true, forKey: Keys.hasConfiguredStartup)
            self.launchAtLogin = true
        } else {
            self.launchAtLogin = LaunchAtLoginHelper.isEnabled
        }

        // Load Macro Items from UserDefaults (empty by default to avoid unexpected expansions like 'vn' -> 'Việt Nam')
        if let data = UserDefaults.standard.data(forKey: Keys.macroItems),
           let decoded = try? JSONDecoder().decode([MacroItem].self, from: data) {
            // Filter out default "vn" -> "Việt Nam" if it was populated from legacy default
            self.macroItems = decoded.filter { !($0.shortcut.lowercased() == "vn" && $0.replacement == "Việt Nam") }
        } else {
            self.macroItems = []
        }

        // Synchronize with the underlying engine immediately
        MoriEngineManager.shared.engine.isEnabled = isEnabled
        MoriEngineManager.shared.engine.inputMethod = inputMethod
        MoriEngineManager.shared.engine.toneStyle = toneStyle
        MoriEngineManager.shared.engine.isSpellingCheckEnabled = spelling
        MoriEngineManager.shared.engine.wAtWordStartAsW = wAtStart
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
