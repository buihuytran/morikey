import Cocoa
import CoreGraphics
import MoriKeyEngine

public final class KeyboardInterceptor {
    public static let shared = KeyboardInterceptor()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var mouseMonitor: Any?

    private init() {}

    public func start() -> Bool {
        let trusted = AccessibilityHelper.isProcessTrusted()
        NSLog("[MoriKey] start() called. isProcessTrusted: %d", trusted ? 1 : 0)
        guard trusted else {
            return false
        }

        if eventTap != nil {
            NSLog("[MoriKey] eventTap is already running")
            return true
        }

        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
        let observer = Unmanaged.passUnretained(self).toOpaque()

        // 1. Try .cghidEventTap first (hardware-level, captures all apps)
        var tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                return KeyboardInterceptor.shared.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: observer
        )

        // 2. If cghidEventTap failed, try .cgSessionEventTap
        if tap == nil {
            NSLog("[MoriKey] cghidEventTap returned nil, trying cgSessionEventTap...")
            tap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: eventMask,
                callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                    return KeyboardInterceptor.shared.handleEvent(proxy: proxy, type: type, event: event)
                },
                userInfo: observer
            )
        }

        guard let validTap = tap else {
            NSLog("[MoriKey] CRITICAL: Failed to create both cghidEventTap and cgSessionEventTap!")
            return false
        }

        NSLog("[MoriKey] SUCCESS: eventTap created successfully!")
        self.eventTap = validTap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, validTap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: validTap, enable: true)

        // Reset buffer when user clicks mouse anywhere
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
            MoriEngineManager.shared.engine.reset()
        }

        return true
    }

    public func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
            self.eventTap = nil
            self.runLoopSource = nil
        }

        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMonitor = nil
        }
    }

    private func handleEvent(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }

        guard type == .keyDown else {
            return Unmanaged.passRetained(event)
        }

        // Ignore our own simulated events to prevent infinite loops
        let tag = event.getIntegerValueField(.eventSourceUserData)
        if tag == KeySimulator.moriEventTag {
            return Unmanaged.passRetained(event)
        }

        let flags = event.flags
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        // Hotkey: Toggle Vietnamese / English
        if keyCode == 0x31 { // Space
            let option = AppSettings.shared.shortcutOption
            var isTriggered = false
            switch option {
            case .controlSpace:
                isTriggered = flags.contains(.maskControl)
            case .optionSpace:
                isTriggered = flags.contains(.maskAlternate)
            case .shiftSpace:
                isTriggered = flags.contains(.maskShift)
            }

            if isTriggered {
                DispatchQueue.main.async {
                    AppSettings.shared.toggleVietnamese()
                }
                return nil
            }
        }

        // If Vietnamese mode is OFF, pass through directly
        if !AppSettings.shared.isEnabled {
            return Unmanaged.passRetained(event)
        }

        // If Cmd, Ctrl, or Option is pressed, pass through & reset buffer
        if flags.contains(.maskCommand) || flags.contains(.maskControl) || flags.contains(.maskAlternate) {
            MoriEngineManager.shared.engine.reset()
            return Unmanaged.passRetained(event)
        }

        // Backspace / Delete (0x33)
        if keyCode == 0x33 {
            MoriEngineManager.shared.engine.handleBackspace()
            return Unmanaged.passRetained(event)
        }

        // Return (0x24), Tab (0x30), Escape (0x35)
        if keyCode == 0x24 || keyCode == 0x30 || keyCode == 0x35 {
            MoriEngineManager.shared.engine.reset()
            return Unmanaged.passRetained(event)
        }

        // Arrow keys (Left: 0x7B, Right: 0x7C, Down: 0x7D, Up: 0x7E)
        if keyCode >= 0x7B && keyCode <= 0x7E {
            MoriEngineManager.shared.engine.reset()
            return Unmanaged.passRetained(event)
        }

        // Extract unicode character
        var actualLength = 0
        var unicodeString = [UniChar](repeating: 0, count: 4)
        event.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &actualLength, unicodeString: &unicodeString)

        guard actualLength > 0, let scalar = UnicodeScalar(unicodeString[0]) else {
            return Unmanaged.passRetained(event)
        }

        let char = Character(scalar)
        let action = MoriEngineManager.shared.engine.process(char: char)

        switch action {
        case .passThrough:
            return Unmanaged.passRetained(event)

        case .replace(let deleteCount, let text):
            let isBrowser = AppSettings.shared.fixBrowserSuggestions && AccessibilityHelper.isFrontmostAppBrowser
            KeySimulator.replace(deleteCount: deleteCount, text: text, fixBrowserAutocomplete: isBrowser)
            return nil
        }
    }
}
