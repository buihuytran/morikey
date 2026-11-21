#!/bin/bash
set -e

CONFIG=${1:-release}
echo "🚀 Building MoriKey ($CONFIG)..."

swift build -c "$CONFIG"

BUILD_DIR=".build/$CONFIG"
# In Apple Silicon / universal, swift build places binaries in .build/arm64-apple-macosx/$CONFIG or .build/$CONFIG
if [ -f ".build/arm64-apple-macosx/$CONFIG/MoriKey" ]; then
    BIN_PATH=".build/arm64-apple-macosx/$CONFIG/MoriKey"
elif [ -f ".build/$CONFIG/MoriKey" ]; then
    BIN_PATH=".build/$CONFIG/MoriKey"
else
    BIN_PATH=$(swift build -c "$CONFIG" --show-bin-path)/MoriKey
fi

APP_DIR="build/MoriKey.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 Packaging into $APP_DIR..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

cp "$BIN_PATH" "$MACOS_DIR/MoriKey"
cp "Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi
if [ -f "Resources/vietqr.png" ]; then
    cp "Resources/vietqr.png" "$RESOURCES_DIR/vietqr.png"
fi

echo "🔏 Signing MoriKey.app with stable designated requirement..."
codesign --force --deep --sign - --identifier "com.mori.morikey" -r='designated => identifier "com.mori.morikey"' "$APP_DIR"

echo "✅ MoriKey.app successfully created at $APP_DIR"

