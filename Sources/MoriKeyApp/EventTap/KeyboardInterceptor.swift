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
        guard AccessibilityHelper.isProcessTrusted() else {
            return false
        }

        if eventTap != nil {
            return true
        }

        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
        let observer = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                return KeyboardInterceptor.shared.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: observer
        ) else {
            return false
        }

        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        // Reset word buffer when user clicks mouse anywhere
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

        // Hotkey: Control + Space -> Toggle Vietnamese / English
        if flags.contains(.maskControl) && keyCode == 0x31 {
            DispatchQueue.main.async {
                AppSettings.shared.toggleVietnamese()
            }
            return nil
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
            // Deliver replacement keystrokes asynchronously on main loop
            // to allow the original suppressed key event to be dropped cleanly first
            DispatchQueue.main.async {
                KeySimulator.sendBackspaces(count: deleteCount)
                KeySimulator.sendString(text)
            }
            return nil
        }
    }
}
