import Cocoa
import SwiftUI
import MoriKeyEngine

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?
    private var permissionWindow: NSWindow?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        updateStatusItemTitle()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateStatusItemTitle),
            name: .moriSettingsChanged,
            object: nil
        )

        // Check accessibility
        if AccessibilityHelper.isProcessTrusted() {
            _ = KeyboardInterceptor.shared.start()
        } else {
            showPermissionGuide()
        }

        // Auto-check timer in case user enables permission in System Settings
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            if AccessibilityHelper.isProcessTrusted() {
                if KeyboardInterceptor.shared.start() {
                    timer.invalidate()
                    self?.permissionWindow?.close()
                    self?.updateStatusItemTitle()
                }
            }
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }

        button.target = self
        button.action = #selector(statusItemClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func updateStatusItemTitle() {
        guard let button = statusItem?.button else { return }
        let isEnabled = AppSettings.shared.isEnabled

        let title = isEnabled ? "🇻🇳 V" : "🔤 E"
        let font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        let attributedTitle = NSAttributedString(
            string: title,
            attributes: [.font: font]
        )
        button.attributedTitle = attributedTitle
        button.toolTip = isEnabled ? "MoriKey: Tiếng Việt (Click để chuyển sang Anh)" : "MoriKey: Tiếng Anh (Click để chuyển sang Việt)"
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let currentEvent = NSApp.currentEvent else { return }

        if currentEvent.type == .rightMouseUp || currentEvent.modifierFlags.contains(.control) {
            showMenu()
        } else {
            // Left click: Toggle Vietnamese / English
            AppSettings.shared.toggleVietnamese()
            updateStatusItemTitle()
        }
    }

    private func showMenu() {
        let menu = NSMenu()

        let statusHeader = NSMenuItem(
            title: AppSettings.shared.isEnabled ? "Bộ gõ: Tiếng Việt [V]" : "Bộ gõ: Tiếng Anh [E]",
            action: #selector(toggleVietnamese),
            keyEquivalent: ""
        )
        statusHeader.target = self
        menu.addItem(statusHeader)

        menu.addItem(NSMenuItem.separator())

        // Input methods submenu
        let inputMethodItem = NSMenuItem(title: "Kiểu gõ", action: nil, keyEquivalent: "")
        let inputMethodMenu = NSMenu()
        for method in InputMethod.allCases {
            let item = NSMenuItem(title: method.rawValue, action: #selector(selectInputMethod(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = method
            item.state = (AppSettings.shared.inputMethod == method) ? .on : .off
            inputMethodMenu.addItem(item)
        }
        inputMethodItem.submenu = inputMethodMenu
        menu.addItem(inputMethodItem)

        // Tone style submenu
        let toneStyleItem = NSMenuItem(title: "Quy tắc đặt dấu", action: nil, keyEquivalent: "")
        let toneStyleMenu = NSMenu()
        for style in ToneStyle.allCases {
            let item = NSMenuItem(title: "\(style.rawValue) (\(style.description))", action: #selector(selectToneStyle(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = style
            item.state = (AppSettings.shared.toneStyle == style) ? .on : .off
            toneStyleMenu.addItem(item)
        }
        toneStyleItem.submenu = toneStyleMenu
        menu.addItem(toneStyleItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Cài đặt...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        if !AccessibilityHelper.isProcessTrusted() {
            let permItem = NSMenuItem(title: "⚠️ Cấp quyền Trợ năng...", action: #selector(showPermissionGuide), keyEquivalent: "")
            permItem.target = self
            menu.addItem(permItem)
        }

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Thoát MoriKey", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil // Clear menu so single left click remains toggle
    }

    @objc private func toggleVietnamese() {
        AppSettings.shared.toggleVietnamese()
    }

    @objc private func selectInputMethod(_ sender: NSMenuItem) {
        if let method = sender.representedObject as? InputMethod {
            AppSettings.shared.inputMethod = method
        }
    }

    @objc private func selectToneStyle(_ sender: NSMenuItem) {
        if let style = sender.representedObject as? ToneStyle {
            AppSettings.shared.toneStyle = style
        }
    }

    @objc public func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 460, height: 420),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Cài đặt MoriKey"
            window.center()
            window.contentView = NSHostingView(rootView: SettingsView())
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc public func showPermissionGuide() {
        if permissionWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 420),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Cấp quyền Trợ năng - MoriKey"
            window.center()
            window.contentView = NSHostingView(rootView: PermissionGuideView(onGranted: { [weak self] in
                self?.permissionWindow?.close()
                self?.updateStatusItemTitle()
            }))
            window.isReleasedWhenClosed = false
            permissionWindow = window
        }

        permissionWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        KeyboardInterceptor.shared.stop()
        NSApplication.shared.terminate(nil)
    }
}

