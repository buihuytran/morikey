import Cocoa

public final class AccessibilityHelper {
    public static func isProcessTrusted() -> Bool {
        return AXIsProcessTrusted()
    }

    public static func requestAccessibilityPermission() {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ]
        _ = AXIsProcessTrustedWithOptions(options)
    }

    public static func openSystemAccessibilitySettings() {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    public static var isFrontmostAppBrowser: Bool {
        guard let bundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier?.lowercased() else {
            return false
        }
        let browserIdentifiers = [
            "com.apple.safari",
            "com.google.chrome",
            "com.microsoft.edgemac",
            "company.thebrowser.browser",
            "com.brave.browser",
            "org.mozilla.firefox",
            "com.operasoftware.opera",
            "com.coccoc.coccoc",
            "org.chromium.chromium",
            "com.vivaldi.vivaldi"
        ]
        for id in browserIdentifiers {
            if bundleId.contains(id) {
                return true
            }
        }
        return false
    }
}

