import Foundation
import MoriKeyEngine

public final class MoriEngineManager {
    public static let shared = MoriEngineManager()

    public let engine: MoriEngine

    private init() {
        self.engine = MoriEngine(
            inputMethod: .telex,
            toneStyle: .modern,
            isEnabled: true
        )
    }
}

