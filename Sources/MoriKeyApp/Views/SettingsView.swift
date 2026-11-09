import SwiftUI
import MoriKeyEngine

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @State private var hasAccessibility = AccessibilityHelper.isProcessTrusted()
    @State private var newShortcut: String = ""
    @State private var newReplacement: String = ""
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            generalTab
                .tabItem {
                    Label("Cơ bản", systemImage: "gearshape")
                }
                .tag(0)

            typingTab
                .tabItem {
                    Label("Kiểu gõ", systemImage: "keyboard")
                }
                .tag(1)

            macroTab
                .tabItem {
                    Label("Gõ tắt", systemImage: "text.badge.plus")
                }
                .tag(2)

            aboutTab
                .tabItem {
                    Label("Giới thiệu", systemImage: "info.circle")
                }
                .tag(3)
        }
        .frame(width: 500, height: 460)
        .onAppear {
            hasAccessibility = AccessibilityHelper.isProcessTrusted()
        }
    }

    // MARK: - Tab 1: General
    private var generalTab: some View {
        Form {
            Section(header: Text("Trạng thái")) {
                Toggle(isOn: $settings.isEnabled) {
                    VStack(alignment: .leading) {
                        Text("Bật bộ gõ tiếng Việt")
                            .fontWeight(.medium)
                        Text(settings.isEnabled ? "Đang bật chế độ tiếng Việt [V]" : "Đang tắt, chế độ tiếng Anh [E]")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Toggle(isOn: $settings.launchAtLogin) {
                    VStack(alignment: .leading) {
                        Text("Khởi động cùng máy tính")
                            .fontWeight(.medium)
                        Text("Tự động mở MoriKey khi đăng nhập vào macOS")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Text("Quyền Trợ năng (Accessibility)")
                    Spacer()
                    if hasAccessibility {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Đã cấp quyền")
                                .foregroundColor(.green)
                        }
                    } else {
                        Button("Cấp quyền ngay") {
                            AccessibilityHelper.openSystemAccessibilitySettings()
                            AccessibilityHelper.requestAccessibilityPermission()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                }
            }

            Section(header: Text("Phím tắt")) {
                Picker("Phím tắt chuyển Việt / Anh:", selection: $settings.shortcutOption) {
                    ForEach(ShortcutOption.allCases) { opt in
                        Text(opt.rawValue).tag(opt)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Tab 2: Typing & Tones
    private var typingTab: some View {
        Form {
            Section(header: Text("Kiểu gõ")) {
                Picker("Chọn kiểu gõ:", selection: $settings.inputMethod) {
                    ForEach(InputMethod.allCases) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(.radioGroup)

                Text(settings.inputMethod.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section(header: Text("Quy tắc đặt dấu thanh")) {
                Picker("Vị trí dấu thanh:", selection: $settings.toneStyle) {
                    ForEach(ToneStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.radioGroup)

                Text(settings.toneStyle.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section(header: Text("Tính năng thông minh")) {
                Toggle(isOn: $settings.wAtWordStartAsW) {
                    VStack(alignment: .leading) {
                        Text("Giữ nguyên chữ 'w' ở đầu từ")
                            .fontWeight(.medium)
                        Text("Tránh việc gõ 'w' (như web, win, wifi, word, www) bị biến thành 'ư'")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Toggle(isOn: $settings.isSpellingCheckEnabled) {
                    VStack(alignment: .leading) {
                        Text("Tự động khôi phục từ tiếng Anh")
                            .fontWeight(.medium)
                        Text("Không biến các từ tiếng Anh (post, test, text, start) thành từ có dấu")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Tab 3: Macro / Shortcuts
    private var macroTab: some View {
        VStack(spacing: 12) {
            HStack {
                Toggle("Bật tính năng gõ tắt", isOn: $settings.isMacroEnabled)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 10)

            // Add new macro bar
            HStack(spacing: 8) {
                TextField("Từ viết tắt (vd: vn)", text: $newShortcut)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 140)

                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)

                TextField("Nội dung thay thế (vd: Việt Nam)", text: $newReplacement)
                    .textFieldStyle(.roundedBorder)

                Button("Thêm") {
                    settings.addMacro(shortcut: newShortcut, replacement: newReplacement)
                    newShortcut = ""
                    newReplacement = ""
                }
                .buttonStyle(.borderedProminent)
                .disabled(newShortcut.isEmpty || newReplacement.isEmpty)
            }
            .padding(.horizontal)

            Divider()

            // List of macros
            List {
                ForEach(settings.macroItems) { item in
                    HStack {
                        Text(item.shortcut)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.semibold)
                            .frame(width: 100, alignment: .leading)

                        Image(systemName: "arrow.right")
                            .foregroundColor(.secondary)
                            .font(.caption)

                        Text(item.replacement)
                            .foregroundColor(.primary)

                        Spacer()

                        Button(role: .destructive) {
                            settings.removeMacro(id: item.id)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
    }

    // MARK: - Tab 4: About
    private var aboutTab: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("🇻🇳")
                .font(.system(size: 64))

            Text("MoriKey")
                .font(.system(size: 24, weight: .bold))

            Text("Bộ gõ Tiếng Việt hiện đại, nhẹ, 100% Native Swift cho macOS")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Phiên bản:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("1.0.0")
                        .fontWeight(.medium)
                }
                HStack {
                    Text("Kiến trúc:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Apple Silicon & Intel")
                        .fontWeight(.medium)
                }
                HStack {
                    Text("Công nghệ:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Swift 6 + SwiftUI + CGEventTap")
                        .fontWeight(.medium)
                }
            }
            .frame(width: 280)
            .padding()
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(10)

            Spacer()
        }
        .padding()
    }
}
