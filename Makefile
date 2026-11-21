export PATH := /opt/homebrew/bin:/usr/local/bin:$(PATH)

.PHONY: all build test test-cpp win app run clean xcode

all: test test-cpp app

test:
	swift test

test-cpp:
	clang++ -std=c++17 -Iwindows/Sources/MoriKeyEngine windows/Sources/MoriKeyEngine/*.cpp windows/Tests/EngineTests.cpp -o build/morikey_cpp_test && ./build/morikey_cpp_test

win:
	@mkdir -p build
	@which x86_64-w64-mingw32-g++ > /dev/null || (echo "Chưa cài mingw-w64. Chạy: brew install mingw-w64" && exit 1)
	x86_64-w64-mingw32-windres windows/Resources/MoriKey.rc -O coff -o build/MoriKey.res
	x86_64-w64-mingw32-g++ -std=c++17 -O3 -mwindows -municode \
		-Iwindows/Sources/MoriKeyEngine \
		-Iwindows/Sources/MoriKeyWinApp \
		-Iwindows/Resources \
		windows/Sources/MoriKeyEngine/*.cpp \
		windows/Sources/MoriKeyWinApp/*.cpp \
		build/MoriKey.res \
		-o build/MoriKey.exe \
		-lcomctl32 -lshell32 -lgdi32 -ladvapi32 \
		-static -static-libgcc -static-libstdc++
	x86_64-w64-mingw32-strip -s build/MoriKey.exe
	@echo "Build thành công! File nằm tại: build/MoriKey.exe"


build:
	swift build

app:
	./scripts/bundle_app.sh release

install: app
	@echo "📦 Cài đặt MoriKey vào /Applications..."
	@rm -rf /Applications/MoriKey.app
	@cp -R build/MoriKey.app /Applications/
	@echo "✅ Đã cài đặt MoriKey vào thư mục Applications! Ứng dụng đã xuất hiện trong Launchpad."

debug-app:
	./scripts/bundle_app.sh debug

run: app
	open build/MoriKey.app

clean:
	rm -rf .build build

xcode:
	xed .

