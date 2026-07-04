#!/bin/bash
#
# BatteryWatts uninstaller.
#   curl -fsSL https://raw.githubusercontent.com/umair-akhtar/BatteryWatts/main/uninstall.sh | bash
#
set -euo pipefail

APP_NAME="BatteryWatts"
LABEL="com.jpert.batterywatts"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

echo "==> Uninstalling $APP_NAME"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
pkill -x "$APP_NAME" 2>/dev/null || true
rm -f "$PLIST"
rm -rf "$HOME/Applications/$APP_NAME.app"
echo "==> Removed. (The menu-bar icon disappears once the app stops.)"
