#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP="BatteryWatts.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"

rm -rf "$APP"
mkdir -p "$MACOS"

echo "Compiling..."
swiftc src/main.swift -o "$MACOS/BatteryWatts"

cat > "$CONTENTS/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>BatteryWatts</string>
    <key>CFBundleDisplayName</key>     <string>BatteryWatts</string>
    <key>CFBundleIdentifier</key>      <string>com.jpert.batterywatts</string>
    <key>CFBundleVersion</key>         <string>1.0</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleExecutable</key>      <string>BatteryWatts</string>
    <key>LSMinimumSystemVersion</key>  <string>12.0</string>
    <key>LSUIElement</key>             <true/>
</dict>
</plist>
PLIST

# Ad-hoc sign so macOS is happy launching it locally
codesign --force --deep --sign - "$APP" 2>/dev/null || true

echo "Built $APP"
