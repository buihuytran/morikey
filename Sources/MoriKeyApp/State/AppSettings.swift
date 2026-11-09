import SwiftUI
import MoriKeyEngine

public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    private enum Keys {
        static let isEnabled = "mori_is_enabled"
        static let inputMethod = "mori_input_method"
        static let toneStyle = "mori_tone_style"
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

    private init() {
        self.isEnabled = UserDefaults.standard.object(forKey: Keys.isEnabled) as? Bool ?? true
        
        let methodRaw = UserDefaults.standard.string(forKey: Keys.inputMethod) ?? InputMethod.telex.rawValue
        self.inputMethod = InputMethod(rawValue: methodRaw) ?? .telex

        let toneRaw = UserDefaults.standard.string(forKey: Keys.toneStyle) ?? ToneStyle.modern.rawValue
        self.toneStyle = ToneStyle(rawValue: toneRaw) ?? .modern
    }

    public func toggleVietnamese() {
        isEnabled.toggle()
    }
}

extension Notification.Name {
    public static let moriSettingsChanged = Notification.Name("moriSettingsChanged")
}

