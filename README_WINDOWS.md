# MoriKey cho Windows 🇻🇳 (Native C++ / Win32 API)

**MoriKey cho Windows** là phiên bản dành riêng cho hệ điều hành Windows (Windows 10, Windows 11, Windows 7/8), được viết **100% bằng C++17 và Win32 API thuần**, mang lại trải nghiệm tương tự UniKey, OpenKey và EVKey:
- 🚀 **Siêu nhẹ & Native**: Kích thước file `.exe` chỉ khoảng ~1MB, không cần cài đặt .NET Framework / Runtime, không tốn RAM / CPU.
- 🎯 **Kiến trúc Hook cấp thấp**: Sử dụng `SetWindowsHookEx(WH_KEYBOARD_LL)` và `SendInput`, tương thích mượt mà với hầu hết các ứng dụng văn phòng, trình duyệt, lập trình (VS Code, Visual Studio, Word, Excel, Chrome, Edge, Telegram, Zalo...).
- 🔤 **Đầy đủ 4 kiểu gõ phổ biến**: Telex, Simple Telex (giữ `w` đầu từ tiếng Anh), VNI, VIQR.
- ⚡ **Khôi phục tiếng Anh thông minh**: Tự động nhận diện từ tiếng Anh phổ biến (`good`, `morning`, `post`, `look`, `system`...) và hoàn tác dấu khi gõ xong từ.
- 🛡️ **Bảng gõ tắt (Macro)**: Hỗ trợ viết tắt linh hoạt, tự động giữ nguyên hoa/thường (ví dụ: `vn` -> `Việt Nam`, `VN` -> `VIỆT NAM`).
- 🔔 **Khay hệ thống (System Tray)**:
  - Icon huy hiệu hiển thị rõ nét chế độ: `[V]` màu đỏ (Tiếng Việt), `[E]` màu xanh (Tiếng Anh).
  - Click chuột trái để chuyển nhanh Việt / Anh.
  - Click chuột phải để mở menu cài đặt nhanh.
  - Phím tắt toàn hệ thống: **`Ctrl + Space`**, **`Alt + Z`**, hoặc **`Ctrl + Shift`**.

---

## 🏗️ Cấu trúc thư mục MoriKey Windows

```text
windows/
├── CMakeLists.txt                         # File cấu hình build CMake cho Windows & Test
├── Resources/
│   ├── resource.h                         # Định danh tài nguyên
│   ├── MoriKey.rc                         # Script tài nguyên Win32 (Version info, Manifest)
│   └── MoriKey.manifest                   # Khai báo Common Controls v6 & Per-Monitor DPI v2
├── Sources/
│   ├── MoriKeyEngine/                     # CORE BỘ GÕ (C++17 ĐỘC LẬP)
│   │   ├── VietnameseChar.h/.cpp          # Bảng mã Unicode, dấu thanh, hoa/thường
│   │   ├── InputMethod.h                  # Định nghĩa Telex, Simple Telex, VNI, VIQR
│   │   ├── ToneRule.h/.cpp                # Quy tắc đặt dấu kiểu Mới (hòa, thúy) & Cũ (hoà, thuý)
│   │   ├── DiacriticTransform.h/.cpp      # Xử lý mũ (â, ê, ô), móc (ơ, ư), đ, hoàn tác double-tap
│   │   ├── VNIRules.h/.cpp                # Xử lý gõ theo số kiểu VNI (1-5, 6-9, 0)
│   │   ├── VIQRTransform.h/.cpp           # Xử lý gõ ký tự kiểu VIQR (^, +, (, -, ', `, ?, ~, .)
│   │   ├── EnglishDictionary.h/.cpp       # Từ điển tiếng Anh & lập trình thông dụng
│   │   ├── SpellingChecker.h/.cpp         # Bộ lọc ngữ âm học & phụ âm tiếng Việt
│   │   ├── MacroEngine.h/.cpp             # Engine gõ tắt
│   │   └── MoriEngine.h/.cpp              # Bộ điều phối nhận phím & sinh thao tác thay thế
│   └── MoriKeyWinApp/                     # ỨNG DỤNG WINDOWS WIN32
│       ├── AppSettings.h/.cpp             # Quản lý cài đặt Registry (HKCU) & Auto-start
│       ├── KeySimulator.h/.cpp            # Giả lập Backspace & chuỗi Unicode qua SendInput
│       ├── KeyboardHook.h/.cpp            # WH_KEYBOARD_LL & WH_MOUSE_LL bắt phím toàn hệ thống
│       ├── TrayIcon.h/.cpp                # Icon System Tray (vẽ huy hiệu [V]/[E] động theo DPI)
│       ├── SettingsDialog.h/.cpp          # Cửa sổ Bảng điều khiển (Tab Control trực quan)
│       └── main.cpp                       # wWinMain, Mutex chống mở trùng, Message Loop
└── Tests/
    └── EngineTests.cpp                    # Bộ 136 Unit Tests tương đương 100% bản Swift
```

---

## 🛠️ Hướng dẫn Biên dịch (Build)

### Cách 1: Build file `MoriKey.exe` trực tiếp trên MacBook (Cross-compile)

Bạn hoàn toàn có thể build ra file `.exe` chạy trên Windows ngay từ chiếc MacBook của mình bằng cách cài đặt công cụ biên dịch chéo `mingw-w64`:

1. Mở Terminal trên Mac và cài đặt `mingw-w64` qua Homebrew:
   ```bash
   brew install mingw-w64
   ```
2. Chạy lệnh:
   ```bash
   make win
   ```
3. File thực thi độc lập **`build/MoriKey.exe`** (~1MB) sẽ được tạo ra ngay trên Mac! Bạn chỉ cần copy file này sang bất kỳ máy tính Windows 10/11 nào là chạy được ngay.

---

### Cách 2: Sử dụng Visual Studio (2019 / 2022) trên Windows

1. Cài đặt **Visual Studio** với workload **"Desktop development with C++"** (Phát triển ứng dụng Desktop bằng C++).
2. Mở Visual Studio -> chọn **"Open a local folder"** -> chọn thư mục `morikey_windows` (hoặc thư mục `windows`).
3. Visual Studio sẽ tự động nhận diện `CMakeLists.txt`.
4. Chọn cấu hình: **`x64-Release`** hoặc **`x86-Release`**.
5. Nhấn **Build** -> **Build All** (`Ctrl + Shift + B`).
6. File thực thi `MoriKey.exe` sẽ được tạo tại thư mục `out/build/x64-Release/MoriKey.exe`.

### Cách 2: Sử dụng dòng lệnh CMake trên Windows

Mở **Command Prompt** (hoặc PowerShell):

```cmd
cd windows
mkdir build
cd build
cmake .. -A x64
cmake --build . --config Release
```

File thực thi `MoriKey.exe` sẽ nằm tại `build/Release/MoriKey.exe`.

### Cách 3: Kiểm tra Unit Tests trên macOS / Linux / Windows

Bạn có thể chạy kiểm tra độ chính xác của Engine C++ ngay trên macOS qua Makefile:

```bash
make test-cpp
```

Kết quả:
```text
Running MoriKey C++ Engine Unit Tests...
---------------------------------------------
Tests Passed: 136
Tests Failed: 0
---------------------------------------------
ALL TESTS PASSED WITH 100% SUCCESS!
```

---

## 🌟 Hướng dẫn Sử dụng trên Windows

1. Chạy file `MoriKey.exe`. 
2. Ứng dụng sẽ tự động thu nhỏ xuống thanh **Khay hệ thống (System Tray)** góc dưới bên phải màn hình:
   - **`[V]` (Đỏ)**: Chế độ gõ tiếng Việt.
   - **`[E]` (Xanh)**: Chế độ gõ tiếng Anh.
3. Nhấn **`Ctrl + Space`** (hoặc `Alt + Z` / `Ctrl + Shift` tuỳ cài đặt) để chuyển đổi qua lại nhanh chóng.
4. Nhấp đúp chuột trái vào biểu tượng ở khay hệ thống để mở **Bảng điều khiển** tùy chỉnh:
   - Thay đổi kiểu gõ: Telex, Simple Telex, VNI, VIQR.
   - Bật/tắt tự động khởi động cùng Windows khi mở máy.
   - Thêm/xóa danh sách từ gõ tắt.

---

## 👤 Tác giả & Liên hệ

- **Tác giả:** Bùi Văn Lợi
- **Địa chỉ:** Kim Bôi - Hòa Bình
- **Email:** [buihuytran.com@gmail.com](mailto:buihuytran.com@gmail.com)
- **GitHub:** [https://github.com/buihuytran](https://github.com/buihuytran)


