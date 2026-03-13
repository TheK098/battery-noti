#!/bin/bash

set -e

REPO_URL="https://raw.githubusercontent.com/TheK098/battery-noti/main"
INSTALL_DIR="$HOME/.local/bin"
PLIST_DIR="$HOME/Library/LaunchAgents"
CONFIG_DIR="$HOME/.config/battery-noti"
PLIST_NAME="com.battery-noti.plist"

echo "Installing battery-noti..."

if launchctl list | grep -q "com.battery-noti"; then
    launchctl unload "$PLIST_DIR/$PLIST_NAME" 2>/dev/null || true
fi

mkdir -p "$INSTALL_DIR"
mkdir -p "$PLIST_DIR"
mkdir -p "$CONFIG_DIR"

SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"

if [ -f "$SCRIPT_DIR/battery-noti.sh" ]; then
    cp "$SCRIPT_DIR/battery-noti.sh" "$INSTALL_DIR/battery-noti.sh"
    sed "s|__HOME__|$HOME|g" "$SCRIPT_DIR/$PLIST_NAME" > "$PLIST_DIR/$PLIST_NAME"
    SWIFT_SRC="$SCRIPT_DIR/alert.swift"
else
    curl -fsSL "$REPO_URL/battery-noti.sh" -o "$INSTALL_DIR/battery-noti.sh"
    curl -fsSL "$REPO_URL/$PLIST_NAME" -o /tmp/battery-noti-plist-tmp
    sed "s|__HOME__|$HOME|g" /tmp/battery-noti-plist-tmp > "$PLIST_DIR/$PLIST_NAME"
    rm -f /tmp/battery-noti-plist-tmp
    curl -fsSL "$REPO_URL/alert.swift" -o /tmp/battery-noti-alert.swift
    SWIFT_SRC="/tmp/battery-noti-alert.swift"
fi

chmod +x "$INSTALL_DIR/battery-noti.sh"

echo "Compiling alert UI..."
if swiftc -O -o "$INSTALL_DIR/battery-noti-alert" "$SWIFT_SRC" 2>/dev/null; then
    chmod +x "$INSTALL_DIR/battery-noti-alert"
    echo "Alert UI compiled"
else
    echo "Warning: Swift compilation failed — falling back to system dialog"
fi
rm -f /tmp/battery-noti-alert.swift

if [ ! -f "$CONFIG_DIR/config" ]; then
    echo "THRESHOLD=3" > "$CONFIG_DIR/config"
    echo "Created config at $CONFIG_DIR/config (threshold: 3%)"
else
    echo "Config already exists at $CONFIG_DIR/config — keeping it"
fi

launchctl load "$PLIST_DIR/$PLIST_NAME"

echo ""
echo "battery-noti installed and running!"
echo "It checks every 60s and alerts when battery drops to $(grep THRESHOLD "$CONFIG_DIR/config" | cut -d= -f2)%."
echo ""
echo "To change the threshold:"
echo "  Edit ~/.config/battery-noti/config"
echo ""
echo "To uninstall:"
echo "  curl -fsSL $REPO_URL/uninstall.sh | bash"
