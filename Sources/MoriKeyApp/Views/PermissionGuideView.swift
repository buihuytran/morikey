import SwiftUI

struct PermissionGuideView: View {
    @State private var isTrusted: Bool = AccessibilityHelper.isProcessTrusted()
    var onGranted: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 54, height: 54)
                .foregroundColor(.blue)

            Text("Yêu cầu quyền Trợ năng (Accessibility)")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Để gõ được tiếng Việt trên macOS, MoriKey cần được cấp quyền Trợ năng trong Cài đặt hệ thống để nhận diện và chuyển đổi ký tự.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Text("1.")
                        .fontWeight(.bold)
                    Text("Nhấn nút bên dưới để mở **Quyền riêng tư & Bảo mật**.")
                }
                HStack(alignment: .top) {
                    Text("2.")
                        .fontWeight(.bold)
                    Text("Chọn mục **Trợ năng (Accessibility)**.")
                }
                HStack(alignment: .top) {
                    Text("3.")
                        .fontWeight(.bold)
                    Text("Bật công tắc cho phép **MoriKey**.")
                }
            }
            .font(.callout)
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)

            HStack(spacing: 16) {
                Button("Mở Cài đặt hệ thống") {
                    AccessibilityHelper.openSystemAccessibilitySettings()
                    AccessibilityHelper.requestAccessibilityPermission()
                }
                .keyboardShortcut(.defaultAction)

                Button("Kiểm tra lại") {
                    let trusted = AccessibilityHelper.isProcessTrusted()
                    isTrusted = trusted
                    if trusted {
                        _ = KeyboardInterceptor.shared.start()
                        onGranted?()
                    }
                }
            }
            .controlSize(.large)
        }
        .padding(30)
        .frame(width: 480)
    }
}

