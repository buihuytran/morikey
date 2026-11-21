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

            donateTab
                .tabItem {
                    Label("Ủng hộ", systemImage: "heart.fill")
                }
                .tag(4)
        }
        .frame(width: 530, height: 490)
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

                Toggle(isOn: $settings.fixBrowserSuggestions) {
                    VStack(alignment: .leading) {
                        Text("Sửa lỗi dấu khi gợi ý (Trình duyệt Safari, Chrome...)")
                            .fontWeight(.medium)
                        Text("Khắc phục hiện tượng lặp chữ hoặc sai dấu trên thanh địa chỉ URL của trình duyệt")
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
                    Text("Tác giả:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Bùi Văn Lợi")
                        .fontWeight(.semibold)
                }
                HStack {
                    Text("Địa chỉ:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Kim Bôi - Hòa Bình")
                        .fontWeight(.medium)
                }
                HStack {
                    Text("Email:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Link("buihuytran.com@gmail.com", destination: URL(string: "mailto:buihuytran.com@gmail.com")!)
                        .fontWeight(.medium)
                }
                HStack {
                    Text("GitHub:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Link("github.com/buihuytran", destination: URL(string: "https://github.com/buihuytran")!)
                        .fontWeight(.medium)
                }

                Divider()
                    .padding(.vertical, 4)

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
            .frame(width: 320)
            .padding()
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(10)

            Spacer()
        }
        .padding()
    }

    // MARK: - Tab 5: Donate
    private var donateTab: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("💖 Ủng Hộ Phát Triển (Donate ☕)")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("Nếu MoriKey hữu ích cho công việc của bạn, hãy ủng hộ tác giả một ly cà phê nhé! ❤️")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(alignment: .top, spacing: 14) {
                    // Việt Nam (VietQR)
                    VStack(spacing: 8) {
                        Text("🇻🇳 Việt Nam (VietQR)")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        if let path = Bundle.main.path(forResource: "vietqr", ofType: "png"),
                           let nsImg = NSImage(contentsOfFile: path) {
                            Image(nsImage: nsImg)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 200)
                                .cornerRadius(8)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Ngân hàng: **MBBank**")
                                .font(.caption)
                            HStack(spacing: 4) {
                                Text("STK: **1907260788**")
                                    .font(.caption)
                                Button {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString("1907260788", forType: .string)
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.caption2)
                                }
                                .buttonStyle(.borderless)
                                .help("Sao chép số tài khoản")
                            }
                            Text("Chủ TK: **BUI VAN LOI**")
                                .font(.caption)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(10)

                    // Quốc Tế (PayPal)
                    VStack(spacing: 12) {
                        Text("🌍 Quốc Tế (PayPal)")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Spacer()

                        Image(systemName: "creditcard.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.blue)

                        Link(destination: URL(string: "https://www.paypal.com/paypalme/buihuytran")!) {
                            HStack(spacing: 6) {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.pink)
                                Text("Ủng hộ qua PayPal")
                                    .fontWeight(.semibold)
                            }
                            .font(.caption)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }

                        Text("👉 Bấm để ủng hộ qua PayPal ($1.99)")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, minHeight: 280)
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 8)
        }
    }
}
