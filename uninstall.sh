#!/bin/bash

PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_NAME="com.battery-noti.plist"

echo "Uninstalling battery-noti..."

if launchctl list | grep -q "com.battery-noti"; then
    launchctl unload "$PLIST_DIR/$PLIST_NAME" 2>/dev/null || true
    echo "Stopped background job"
fi

rm -f "$PLIST_DIR/$PLIST_NAME"
rm -f "$HOME/.local/bin/battery-noti.sh"
rm -rf "$HOME/.config/battery-noti"
rm -f /tmp/battery-noti.lock

echo "battery-noti uninstalled."
