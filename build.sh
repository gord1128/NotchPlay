#!/bin/bash
set -e

BUILD_DIR="./build/NotchPlay.app"
APP_DIR="/Applications/NotchPlay.app"

# 1. Create Local Build Directory Structure
echo "🧹 Cleaning previous build..."
rm -rf ./build
mkdir -p "$BUILD_DIR/Contents/MacOS"
mkdir -p "$BUILD_DIR/Contents/Resources"

# 2. Create Info.plist in Build Dir
cat <<EOF > "$BUILD_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>NotchPlay</string>
    <key>CFBundleIdentifier</key>
    <string>com.antigravity.notchplay</string>
    <key>CFBundleName</key>
    <string>NotchPlay</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>NotchPlay needs permission to control Spotify and Apple Music.</string>
</dict>
</plist>
EOF

# 3. Kill running instance if exists
killall NotchPlay 2>/dev/null || true

# 4. Compile into Local Build Dir
echo "🔨 Compiling NotchPlay into isolated build directory..."
xcrun swiftc src/App.swift src/NotchView.swift src/NotchWindowController.swift src/SystemMediaManager.swift src/SystemAudioManager.swift src/LyricsManager.swift src/HotkeyRecorderView.swift src/HotkeyHelper.swift src/FuriganaHelper.swift \
    -o "$BUILD_DIR/Contents/MacOS/NotchPlay" \
    -parse-as-library \
    -target arm64-apple-macos13.0

# 5. Sign the Local Build
echo "🔐 Signing NotchPlay..."
codesign --force --deep --sign - "$BUILD_DIR"

# 6. Check if it is running in CI/Release mode
if [ "$1" == "--release" ]; then
    echo "📦 Release build completed at $BUILD_DIR"
    exit 0
fi

# 7. For local dev: Copy to /Applications and run
echo "🚀 Copying to /Applications for local testing..."
rm -rf "$APP_DIR"
cp -R "$BUILD_DIR" "$APP_DIR"
open "$APP_DIR"
