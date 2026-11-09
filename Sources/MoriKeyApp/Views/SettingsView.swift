import SwiftUI
import MoriKeyEngine

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @State private var hasAccessibility = AccessibilityHelper.isProcessTrusted()

    var body: some View {
        Form {
            Section(header: Text("Trạng thái hoạt động")) {
                Toggle(isOn: $settings.isEnabled) {
                    VStack(alignment: .leading) {
                        Text("Bật bộ gõ tiếng Việt")
                            .fontWeight(.medium)
                        Text(settings.isEnabled ? "Đang bật chế độ gõ tiếng Việt [V]" : "Đang tắt, ở chế độ tiếng Anh [E]")
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

            Section(header: Text("Kiểu gõ")) {
                Picker("Kiểu gõ:", selection: $settings.inputMethod) {
                    ForEach(InputMethod.allCases) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(.segmented)

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

            Section(header: Text("Thông tin ứng dụng")) {
                HStack {
                    Text("Phiên bản")
                    Spacer()
                    Text("1.0.0 (Native Swift)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Kiến trúc")
                    Spacer()
                    Text("Apple Silicon & Intel (macOS)")
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 420)
        .onAppear {
            hasAccessibility = AccessibilityHelper.isProcessTrusted()
        }
    }
}

