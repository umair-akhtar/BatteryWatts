#!/bin/bash
#
# BatteryWatts installer.
# Run directly:
#   curl -fsSL https://raw.githubusercontent.com/umair-akhtar/BatteryWatts/main/install.sh | bash
#
set -euo pipefail

REPO="umair-akhtar/BatteryWatts"
APP_NAME="BatteryWatts"
APP="$APP_NAME.app"
LABEL="com.jpert.batterywatts"
INSTALL_DIR="$HOME/Applications"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

echo "==> Installing $APP_NAME"

mkdir -p "$INSTALL_DIR" "$HOME/Library/LaunchAgents"

# Get the app: prefer a local build ONLY when genuinely run from a checkout, else
# download the latest release.
#
# Security: when invoked the documented way (`curl -fsSL .../install.sh | bash`),
# BASH_SOURCE is empty and dirname resolves to the *current working directory*.
# We must NOT treat a "BatteryWatts.app" sitting in the cwd as a trusted local
# build — an attacker could plant one in a shared/world-writable dir and have it
# installed, re-signed, and persisted via the LaunchAgent. So the local-build path
# is taken only when this script exists as a real file on disk next to the app.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

SCRIPT_SRC="${BASH_SOURCE[0]:-}"
SCRIPT_DIR=""
if [ -n "$SCRIPT_SRC" ] && [ -f "$SCRIPT_SRC" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SRC")" && pwd)"
fi

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/install.sh" ] && [ -d "$SCRIPT_DIR/$APP" ]; then
    echo "==> Using locally built app at $SCRIPT_DIR/$APP"
    SRC_APP="$SCRIPT_DIR/$APP"
else
    URL="https://github.com/$REPO/releases/latest/download/$APP_NAME.zip"
    echo "==> Downloading $URL"
    curl -fsSL "$URL" -o "$TMP/$APP_NAME.zip"
    ditto -x -k "$TMP/$APP_NAME.zip" "$TMP"
    SRC_APP="$TMP/$APP"
fi

# Stop any running/old instance first.
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
pkill -x "$APP_NAME" 2>/dev/null || true

# Install into ~/Applications.
rm -rf "$INSTALL_DIR/$APP"
ditto "$SRC_APP" "$INSTALL_DIR/$APP"

# Clear Gatekeeper quarantine and (re)apply an ad-hoc signature so it launches without prompts.
xattr -dr com.apple.quarantine "$INSTALL_DIR/$APP" 2>/dev/null || true
codesign --force --sign - "$INSTALL_DIR/$APP" 2>/dev/null || true

# Write a LaunchAgent with the correct per-machine paths so it auto-starts on login.
cat > "$PLIST" <<PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/$APP/Contents/MacOS/$APP_NAME</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
PLISTEOF

# Load it (starts the app immediately and on every login).
launchctl bootstrap "gui/$(id -u)" "$PLIST"

echo "==> Done. $APP_NAME is now in your menu bar and will start automatically on login."
echo "    To uninstall: curl -fsSL https://raw.githubusercontent.com/$REPO/main/uninstall.sh | bash"
