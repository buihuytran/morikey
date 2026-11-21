# MoriKey 🇻🇳 - Bộ gõ Tiếng Việt Native cho macOS & Windows

[![Release](https://img.shields.io/github/v/release/buihuytran/morikey?label=Bản%20phát%20hành&color=success)](https://github.com/buihuytran/morikey/releases/latest)
[![Platform](https://img.shields.io/badge/Hỗ%20trợ-macOS%20%7C%20Windows-blue)](https://github.com/buihuytran/morikey/releases/latest)

**MoriKey** là phần mềm bộ gõ tiếng Việt hiện đại, nhẹ:
- **macOS**: Viết 100% bằng Swift và SwiftUI, chạy trực tiếp trên Menu Bar qua CGEventTap.
- **Windows**: Viết 100% bằng C++17 và Win32 API thuần (không cần runtime, tương tự UniKey / EVKey), chạy tại Khay hệ thống (System Tray) qua `SetWindowsHookEx`. Xem chi tiết tại [README_WINDOWS.md](file:///Users/macbook/Downloads/UNGDUNG/morikey_windows/README_WINDOWS.md).

---

## 📥 Tải về ứng dụng (Downloads)

| Hệ điều hành | File tải về | Hướng dẫn sử dụng |
| :--- | :--- | :--- |
| **Windows** (10 / 11 / 7) | [**Tải MoriKey.exe**](https://github.com/buihuytran/morikey/releases/latest/download/MoriKey.exe) | File chạy ngay (~1.1 MB), không cần cài đặt. |
| **macOS** (Apple Silicon & Intel) | [**Tải MoriKey-macOS.zip**](https://github.com/buihuytran/morikey/releases/latest/download/MoriKey-macOS.zip) | Giải nén kéo vào Applications để chạy. |

---

## ✨ Tính năng nổi bật

- ⚡️ **Native & Siêu nhẹ**: Viết thuần Swift 5.9+ / Swift 6, không dùng webview hay runtime cồng kềnh, tiêu tốn rất ít RAM và CPU.
- ⌨️ **Hỗ trợ đầy đủ 4 kiểu gõ phổ biến nhất**:
  - **Telex**: Kiểu gõ phổ thông nhất (`aa` -> `â`, `aw` -> `ă`, `ee` -> `ê`, `oo` -> `ô`, `ow` -> `ơ`, `uw` -> `ư`, `uow` -> `ươ`, `dd` -> `đ`, `s/f/r/x/j/z`). Hỗ trợ gõ nhanh ngoặc vuông: `[` -> `ơ`, `]` -> `ư`.
  - **Simple Telex**: Giữ nguyên `w` ở đầu từ tiếng Anh (ví dụ: `web`, `win`, `wifi`), giảm thiểu gõ nhầm.
  - **VNI**: Kiểu gõ theo số (`1`: sắc, `2`: huyền, `3`: hỏi, `4`: ngã, `5`: nặng, `6`: â/ê/ô, `7`: ơ/ư, `8`: ă, `9`: đ, `0`: xóa dấu). Gõ đúp số để khôi phục số (`a11` -> `a1`).
  - **VIQR**: Kiểu gõ theo ký tự quy chuẩn (`'`: sắc, `` ` ``: huyền, `?`: hỏi, `~`: ngã, `.`: nặng, `^`: mũ, `+`: móc, `(`: trăng, `d-`: đ).
- ⌨️ **Phím tắt toàn hệ thống**: Nhấn **`⌃ Space` (Control + Space)** để chuyển đổi tức thì giữa Tiếng Việt `[V]` và Tiếng Anh `[E]` mà không cần dùng chuột!
- 🎯 **Quy tắc dấu linh hoạt**:
  - **Kiểu mới**: `hòa`, `thúy`, `khỏe`
  - **Kiểu cũ**: `hoà`, `thuý`, `khoẻ`
- 🇻🇳/🔤 **Chuyển đổi nhanh**: Click vào biểu tượng trên Menu Bar để chuyển nhanh giữa chế độ Tiếng Việt `[V]` và Tiếng Anh `[E]`. Chuột phải hoặc Control-click để mở menu tuỳ chọn.
- 🛡️ **Kiến trúc tách bạch (Modular Core)**:
  - `MoriKeyEngine`: Core thư viện xử lý tiếng Việt độc lập, không dính UI, có bộ Unit Tests kiểm tra độ chuẩn xác.
  - `MoriKeyApp`: Menu Bar App bằng SwiftUI & EventTap.

---

## 🏗️ Cấu trúc thư mục dự án

```text
morikey/
├── Package.swift                     # Khai báo Swift Package (tương thích Xcode & Terminal)
├── Makefile                          # Các lệnh tiện ích: build, test, app, run
├── Resources/
│   └── Info.plist                    # Bundle metadata (LSUIElement = true để chạy menu bar)
├── scripts/
│   └── bundle_app.sh                 # Script đóng gói binary thành MoriKey.app và ký mã ad-hoc
├── Sources/
│   ├── MoriKeyEngine/                # CORE BỘ GÕ TIẾNG VIỆT
│   │   ├── Models/
│   │   │   ├── InputMethod.swift     # Enum Telex, Simple Telex, Tone
│   │   │   └── VietnameseChar.swift  # Bảng ký tự Unicode tiếng Việt, bảng dấu
│   │   ├── Transformer/
│   │   │   ├── ToneRule.swift        # Thuật toán định vị nguyên âm nhận dấu
│   │   │   └── DiacriticTransform.swift # Xử lý biến đổi mũ, móc (â, ă, ê, ô, ơ, ư, đ)
│   │   └── MoriEngine.swift          # Giao diện chính của Engine, quản lý buffer từ gõ
│   └── MoriKeyApp/                   # MACOS APP & GIAO DIỆN
│       ├── main.swift                # Điểm khởi chạy ứng dụng
│       ├── AppDelegate.swift         # Quản lý NSStatusItem trên Menu Bar, Menu ngữ cảnh
│       ├── EventTap/
│       │   ├── KeyboardInterceptor.swift # CGEventTap lắng nghe phím toàn hệ thống
│       │   ├── KeySimulator.swift        # Giả lập phím Backspace & chèn ký tự Unicode
│       │   └── AccessibilityHelper.swift # Kiểm tra & xin quyền Trợ năng (Accessibility)
│       ├── State/
│       │   ├── AppSettings.swift         # Lưu cài đặt (UserDefaults)
│       │   └── MoriEngineManager.swift   # Quản lý instance Engine
│       └── Views/
│           ├── SettingsView.swift        # Cửa sổ Cài đặt giao diện SwiftUI
│           └── PermissionGuideView.swift # Hướng dẫn cấp quyền Trợ năng
└── Tests/
    └── MoriKeyEngineTests/
        └── EngineTests.swift         # Unit tests kiểm tra quy tắc gõ & dấu thanh
```

---

## 🚀 Hướng dẫn cài đặt & Chạy

### 1. Yêu cầu hệ thống
- macOS 13.0 (Ventura) trở lên.
- Đã cài đặt **Xcode** hoặc **Command Line Tools** (`swift --version`).

### 2. Sử dụng lệnh nhanh qua Makefile

Chạy Terminal tại thư mục dự án `morikey`:

- **Chạy kiểm tra tự động (Unit Tests):**
  ```bash
  make test
  ```
- **Đóng gói ứng dụng `MoriKey.app`:**
  ```bash
  make app
  ```
  Ứng dụng hoàn chỉnh sẽ được tạo tại `build/MoriKey.app`.

- **Mở và chạy trực tiếp:**
  ```bash
  make run
  ```

- **Mở dự án trong Xcode để phát triển tiếp:**
  ```bash
  make xcode
  ```
  *(Hoặc mở file `Package.swift` bằng Xcode)*

---

## 🔒 Hướng dẫn cấp quyền Trợ năng (Accessibility)

Do macOS bảo vệ quyền riêng tư người dùng, mọi phần mềm bộ gõ chạy kiểu Event Tap đều cần quyền Trợ năng để đọc và thay thế phím:

1. Khi khởi chạy MoriKey lần đầu, một hộp thoại hướng dẫn sẽ xuất hiện.
2. Nhấn nút **"Mở Cài đặt hệ thống"** (hoặc vào **System Settings** > **Privacy & Security** > **Accessibility**).
3. Bật công tắc cho phép **MoriKey**.
4. Quay lại MoriKey nhấn **"Kiểm tra lại"** — biểu tượng `[V]` sẽ sẵn sàng hoạt động ngay trên menu bar!

---

## 💡 Mở rộng trong tương lai

Dự án được thiết kế theo module rất dễ mở rộng:
- **Thêm kiểu gõ VNI**: Thêm logic map phím số `1..9` vào thư mục `MoriKeyEngine/Transformer/`.
- **Bảng gõ tắt (Macro / Shortcuts)**: Thêm Dictionary lưu trữ từ viết tắt trong `MoriEngine`.
- **Tự động khôi phục từ tiếng Anh (Spelling check)**: Kiểm tra các tiền tố/hậu tố không tồn tại trong tiếng Việt để tự động phục hồi chữ tiếng Anh.

---

## 👤 Tác giả & Liên hệ

- **Tác giả:** Bùi Văn Lợi
- **Địa chỉ:** Kim Bôi - Hòa Bình
- **Email:** [buihuytran.com@gmail.com](mailto:buihuytran.com@gmail.com)
- **GitHub:** [https://github.com/buihuytran](https://github.com/buihuytran)


