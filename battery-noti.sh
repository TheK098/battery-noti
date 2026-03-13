#!/bin/bash

LOCKFILE="/tmp/battery-noti.lock"
if [ -f "$LOCKFILE" ] && kill -0 "$(cat "$LOCKFILE")" 2>/dev/null; then
    exit 0
fi
echo $$ > "$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT

CONFIG_FILE="$HOME/.config/battery-noti/config"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

THRESHOLD=${THRESHOLD:-3}

get_battery_percent() {
    pmset -g batt | grep -Eo '[0-9]+%' | head -1 | tr -d '%'
}

is_charging() {
    pmset -g batt | grep -q "AC Power"
}

if is_charging; then
    exit 0
fi

BATTERY=$(get_battery_percent)

if [ -z "$BATTERY" ]; then
    exit 0
fi

if [ "$BATTERY" -le "$THRESHOLD" ]; then
    while true; do
        if is_charging; then
            exit 0
        fi

        BATTERY=$(get_battery_percent)

        osascript -e "
            display dialog \"⚠️ BATTERY AT ${BATTERY}% — PLUG IN NOW\" \
                with title \"battery-noti\" \
                with icon stop \
                buttons {\"OK\"} \
                default button \"OK\" \
                giving up after 25
        " 2>/dev/null

        sleep 30

        if is_charging; then
            exit 0
        fi
    done
fi
