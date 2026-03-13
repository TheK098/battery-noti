# battery-noti

Mac doesn't tell you when it's about to die at 2% and it's incredibly annoying. This fixes that.

A tiny, invisible background script that does **nothing** until your battery hits a critical level — then throws an impossible-to-ignore dialog in your face until you plug in.

- Zero CPU, zero memory, zero battery impact
- No menu bar icon, no dock icon, nothing visible
- When triggered: a modal dialog that **keeps coming back every 30 seconds** until you plug in

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/TheK098/battery-noti/main/setup.sh | bash
```

## Configure

Edit `~/.config/battery-noti/config`:

```
THRESHOLD=3
```

Change the number to whatever % you want the alert at. Default is 3%.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/TheK098/battery-noti/main/uninstall.sh | bash
```

## How it works

`launchd` runs a shell script every 60 seconds. The script calls `pmset -g batt` (takes ~5ms), checks the battery %, and exits. When the battery drops to your threshold, it enters a loop showing a system dialog every 30 seconds until you plug in. Nothing stays in memory between checks.
