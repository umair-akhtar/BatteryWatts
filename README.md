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

Universal build — runs natively on both **Apple Silicon and Intel** Macs (macOS 12+).

## Install (one command)

Open **Terminal** and paste:

```sh
curl -fsSL https://raw.githubusercontent.com/umair-akhtar/BatteryWatts/main/install.sh | bash
```

That downloads the latest release, installs it to `~/Applications`, clears the
Gatekeeper quarantine so it opens without warnings, and sets it to start on login.
The icon appears in your menu bar within a couple of seconds. Run the same command
on each of your Macs.

### Uninstall

```sh
curl -fsSL https://raw.githubusercontent.com/umair-akhtar/BatteryWatts/main/uninstall.sh | bash
```

## Install manually (from a downloaded zip)

If you download `BatteryWatts.zip` from the [Releases page](https://github.com/umair-akhtar/BatteryWatts/releases) instead:

```sh
cd ~/Downloads
unzip BatteryWatts.zip
xattr -dr com.apple.quarantine BatteryWatts.app   # clear Gatekeeper flag
mv BatteryWatts.app ~/Applications/
open ~/Applications/BatteryWatts.app
```

> **Why the `xattr` step?** The app is ad-hoc signed (no paid Apple Developer ID),
> so anything downloaded through a browser gets quarantined by Gatekeeper. Clearing
> the flag — or right-clicking the app and choosing **Open** the first time — lets it run.
> The `curl | bash` installer above does this for you automatically.

## Build from source

```sh
git clone https://github.com/umair-akhtar/BatteryWatts.git
cd BatteryWatts
./build.sh                # produces a universal BatteryWatts.app
./install.sh              # installs the local build + sets up auto-start
```

## How it works

Reads Apple's `AppleSmartBattery` IOKit registry (`Voltage`, `Amperage`, `AdapterDetails`,
`AvgTimeToFull`, `AppleRawCurrentCapacity`) every 5 seconds. No dock icon (`LSUIElement`),
no external dependencies, **no network access**.

## Requirements

- macOS 12.0 or later
- To build: the Swift toolchain (`swiftc`) from Xcode Command Line Tools (`xcode-select --install`)
