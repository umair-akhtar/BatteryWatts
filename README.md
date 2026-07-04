# BatteryWatts

A tiny native macOS **menu-bar app** that shows live charging info next to the battery icon.

When the charger is plugged in, the menu bar reads:

```
⚡ 29/100W · 3:07 · 14%
```

- **29** — watts flowing into the battery right now (charging power = voltage × amperage)
- **100** — the charger's max wattage rating
- **3:07** — estimated time until fully charged
- **14%** — current battery charge

On battery power it collapses to `🔋 14%`. Clicking the item shows the same details spelled out.

## How it works

Reads Apple's `AppleSmartBattery` IOKit registry (`Voltage`, `Amperage`, `AdapterDetails`,
`AvgTimeToFull`, `AppleRawCurrentCapacity`) every 5 seconds. No dock icon (`LSUIElement`),
no external dependencies, no network access.

## Build

```sh
./build.sh
```

Produces `BatteryWatts.app`. Launch it with `open BatteryWatts.app`.

## Auto-start on login

A LaunchAgent keeps it running:

```sh
cp com.jpert.batterywatts.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.jpert.batterywatts.plist
```

## Requirements

- macOS 12.0+
- Swift toolchain (`swiftc`, ships with Xcode Command Line Tools)
