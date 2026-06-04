#!/bin/bash
set -e

BUILD_DIR="./build/NotchPlay.app"
APP_DIR="/Applications/NotchPlay.app"

# 1. Read Version
APP_VERSION="1.0.0"
if [ -f ".version" ]; then
    APP_VERSION=$(cat ".version")
fi

# 2. Create Local Build Directory Structure
echo "🧹 Cleaning previous build..."
rm -rf ./build
mkdir -p "$BUILD_DIR/Contents/MacOS"
mkdir -p "$BUILD_DIR/Contents/Resources"

if [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "$BUILD_DIR/Contents/Resources/AppIcon.icns"
fi
if [ -d "assets" ]; then
    cp assets/*.png "$BUILD_DIR/Contents/Resources/" 2>/dev/null || true
    cp assets/*.icns "$BUILD_DIR/Contents/Resources/" 2>/dev/null || true
fi

# 3. Create Info.plist in Build Dir
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
    <string>${APP_VERSION}</string>
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

# 4. Kill running instance if exists
killall NotchPlay 2>/dev/null || true

# 5. Compile into Local Build Dir
echo "🔨 Compiling NotchPlay into isolated build directory..."
xcrun swiftc src/App.swift src/NotchView.swift src/SceneKitTurntableView.swift src/NotchWindowController.swift src/SystemMediaManager.swift src/SystemAudioManager.swift src/LyricsManager.swift src/HotkeyRecorderView.swift src/HotkeyHelper.swift src/FuriganaHelper.swift src/AutoUpdater.swift \
    -o "$BUILD_DIR/Contents/MacOS/NotchPlay" \
    -parse-as-library \
    -target arm64-apple-macos13.0

# 6. Sign the Local Build with a stable Designated Requirement
echo "🔐 Signing NotchPlay (with stable requirements for Accessibility)..."
codesign --force --deep --sign - --requirements '=designated => identifier "com.antigravity.notchplay"' "$BUILD_DIR"

# 7. Check if it is running in CI/Release mode
if [ "$1" == "--release" ]; then
    echo "📦 Release build completed at $BUILD_DIR"
    exit 0
fi

# 8. For local dev: Copy to /Applications and run
echo "🚀 Copying to /Applications for local testing..."
rm -rf "$APP_DIR"
cp -R "$BUILD_DIR" "$APP_DIR"
open "$APP_DIR"
