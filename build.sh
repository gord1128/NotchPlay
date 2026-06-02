#!/bin/bash
set -e

# Create App Bundle Structure
mkdir -p /Applications/NotchPlay.app/Contents/MacOS
mkdir -p /Applications/NotchPlay.app/Contents/Resources

# Create Info.plist
cat <<EOF > /Applications/NotchPlay.app/Contents/Info.plist
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

# Kill running instance
killall NotchPlay 2>/dev/null || true

# Compile
echo "Compiling NotchPlay..."
xcrun swiftc src/App.swift src/NotchView.swift src/NotchWindowController.swift src/SystemMediaManager.swift src/SystemAudioManager.swift src/LyricsManager.swift src/HotkeyRecorderView.swift src/HotkeyHelper.swift src/FuriganaHelper.swift \
    -o /Applications/NotchPlay.app/Contents/MacOS/NotchPlay \
    -parse-as-library \
    -target arm64-apple-macos13.0

# Sign
echo "Signing NotchPlay..."
codesign --force --deep --sign - /Applications/NotchPlay.app

# Open
echo "Launching NotchPlay..."
open /Applications/NotchPlay.app
