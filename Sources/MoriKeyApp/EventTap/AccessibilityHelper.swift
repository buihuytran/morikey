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
        // 1. Check if Spotlight is active:
        if let spotlight = NSWorkspace.shared.runningApplications.first(where: {
            ($0.bundleIdentifier ?? "").lowercased().contains("spotlight")
        }), spotlight.isActive {
            return true
        }

        guard let bundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier?.lowercased() else {
            // When Spotlight / system search is active, frontmostApplication can be nil
            return true
        }

        let autocompleteIdentifiers = [
            "safari", "chrome", "edge", "browser", "brave", "firefox", "opera",
            "coccoc", "chromium", "vivaldi", "spotlight", "search", "store",
            "finder", "alfred", "raycast", "launcher"
        ]
        for id in autocompleteIdentifiers {
            if bundleId.contains(id) {
                return true
            }
        }
        return false
    }
}

