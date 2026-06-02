#!/bin/bash
set -e

APP_NAME="NotchPlay"
APP_BUNDLE="/Applications/NotchPlay.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICON_DIR="NotchPlay.iconset"
SOURCE_IMAGE="/Users/hyeonm9/.gemini/antigravity/brain/0a012dc9-1ac4-460b-b6a2-5cceddbc6ac7/app_icon_base_1780087790613.png"

mkdir -p "$ICON_DIR"

# Generate different sizes, explicitly forcing PNG format
sips -s format png -z 16 16     "$SOURCE_IMAGE" --out "$ICON_DIR/icon_16x16.png"
sips -s format png -z 32 32     "$SOURCE_IMAGE" --out "$ICON_DIR/icon_16x16@2x.png"
sips -s format png -z 32 32     "$SOURCE_IMAGE" --out "$ICON_DIR/icon_32x32.png"
sips -s format png -z 64 64     "$SOURCE_IMAGE" --out "$ICON_DIR/icon_32x32@2x.png"
sips -s format png -z 128 128   "$SOURCE_IMAGE" --out "$ICON_DIR/icon_128x128.png"
sips -s format png -z 256 256   "$SOURCE_IMAGE" --out "$ICON_DIR/icon_128x128@2x.png"
sips -s format png -z 256 256   "$SOURCE_IMAGE" --out "$ICON_DIR/icon_256x256.png"
sips -s format png -z 512 512   "$SOURCE_IMAGE" --out "$ICON_DIR/icon_256x256@2x.png"
sips -s format png -z 512 512   "$SOURCE_IMAGE" --out "$ICON_DIR/icon_512x512.png"
sips -s format png -z 1024 1024 "$SOURCE_IMAGE" --out "$ICON_DIR/icon_512x512@2x.png"

# Compile to icns
iconutil -c icns "$ICON_DIR" -o AppIcon.icns

# Copy to app resources
mkdir -p "$RESOURCES_DIR"
cp AppIcon.icns "$RESOURCES_DIR/"

# Clean up
rm -rf "$ICON_DIR" AppIcon.icns

# Create Info.plist
cat <<EOF > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>NotchPlay</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.hyeonm9.notchplay.app</string>
    <key>CFBundleName</key>
    <string>NotchPlay</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>2</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>NotchPlay needs to control Spotify to show your current track and manage playback.</string>
</dict>
</plist>
EOF

echo "App icon generated and Info.plist created successfully."
