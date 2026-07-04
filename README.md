<div align="center">

# 🔋 BatteryWatts

**A tiny native macOS menu-bar app that shows live charging power right next to your battery icon.**

[![Release](https://img.shields.io/github/v/release/umair-akhtar/BatteryWatts?color=brightgreen)](https://github.com/umair-akhtar/BatteryWatts/releases/latest)
[![Platform](https://img.shields.io/badge/platform-macOS%2012%2B-lightgrey)](https://github.com/umair-akhtar/BatteryWatts)
[![Universal](https://img.shields.io/badge/binary-universal%20(arm64%20%2B%20x86__64)-blue)](https://github.com/umair-akhtar/BatteryWatts)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![No Network](https://img.shields.io/badge/network-none-success)](https://github.com/umair-akhtar/BatteryWatts)

</div>

---

macOS tells you your battery percentage — but not **how fast it's actually charging**, what your charger is capable of, or **when it'll be full**. BatteryWatts puts all of that in your menu bar in a single compact readout, updated live every few seconds.

```
⚡ 29/100W · 3:07 · 14%
```

<div align="center">

| Field | Example | Meaning |
|:-----:|:-------:|:--------|
| ⚡ Charging watts | `29` | Power flowing **into the battery** right now (voltage × amperage) |
| Charger watts | `100` | Your charger's wattage — the peak it has delivered this session |
| Time to full | `3:07` | Estimated time remaining until 100% |
| Battery % | `14%` | Current charge level |

</div>

When you unplug, it collapses to a clean `🔋 14%`. Click the icon any time for the same details spelled out in a dropdown.

> 💡 **Why the charging watts are lower than your charger's rating:** a MacBook only pulls its charger's full wattage when the battery is low *and* the system is under load. As the battery fills, charging naturally tapers — so seeing `29/100W` at 14% is completely normal. Watch it climb, then ease off as it tops up.
>
> 💡 **About the charger number:** macOS doesn't expose a static "nameplate" wattage — it only reports the *currently negotiated* USB-C Power Delivery wattage, which tapers as the battery fills (a 100 W charger negotiates 100 W at a low battery but only ~30 W near full; Apple's own System Information shows the same tapering value). BatteryWatts therefore **peak-holds** the highest wattage seen since you plugged in, which reflects your charger's true capability. If you plug in when the battery is already nearly full, it may briefly show a lower number until the charger ramps up — it "learns" the full figure the first time real power is drawn. The dropdown also shows the live "Drawing now" figure for full transparency.

---

## ✨ Features

- **Live charging power** in watts — the number Apple hides from you.
- **Time until full**, using macOS's own estimate (matches `pmset`).
- **Charger wattage** so you can tell a 100W brick from a 30W one at a glance.
- **Universal binary** — runs natively on **Apple Silicon and Intel** Macs, no Rosetta.
- **Featherweight** — a single ~100KB binary, no frameworks, no background daemons beyond one login item.
- **Zero network access.** It reads only local hardware telemetry. Nothing leaves your Mac. ([See how it works](#-how-it-works).)
- **No dock icon** — lives entirely in the menu bar (`LSUIElement`).
- **Auto-starts on login** via a per-user LaunchAgent.

---

## 📦 Installation

### Option 1 — One command (recommended)

Open **Terminal** and paste:

```sh
curl -fsSL https://raw.githubusercontent.com/umair-akhtar/BatteryWatts/main/install.sh | bash
```

This downloads the latest release, installs it to `~/Applications`, clears the
Gatekeeper quarantine flag so it opens without warnings, and sets it to launch on
login. The icon appears in your menu bar within a couple of seconds. Run the same
command on each of your Macs.

### Option 2 — Download the app manually

1. Grab `BatteryWatts.zip` from the [**latest release**](https://github.com/umair-akhtar/BatteryWatts/releases/latest).
2. Unzip it and move `BatteryWatts.app` to `~/Applications` (or `/Applications`).
3. Clear the Gatekeeper flag, then open it:

```sh
xattr -dr com.apple.quarantine ~/Applications/BatteryWatts.app
open ~/Applications/BatteryWatts.app
```

> **Why the `xattr` step?** The app is *ad-hoc signed* (it isn't distributed through
> a paid Apple Developer account), so anything you download through a **browser** gets
> quarantined by Gatekeeper. Clearing the flag — or right-clicking the app and choosing
> **Open** the first time — lets it run. The one-command installer above does this for you.

### Option 3 — Build from source

Requires the Swift toolchain from Xcode Command Line Tools (`xcode-select --install`):

```sh
git clone https://github.com/umair-akhtar/BatteryWatts.git
cd BatteryWatts
./build.sh        # compiles a universal BatteryWatts.app
./install.sh      # installs the local build + sets up auto-start
```

---

## 🗑️ Uninstall

```sh
curl -fsSL https://raw.githubusercontent.com/umair-akhtar/BatteryWatts/main/uninstall.sh | bash
```

This stops the app, removes the LaunchAgent, and deletes `~/Applications/BatteryWatts.app`.
Or, to quit for the current session only, click the menu-bar icon → **Quit BatteryWatts**.

---

## 🔧 How it works

BatteryWatts reads Apple's private-but-stable `AppleSmartBattery` entry from the
**IOKit registry** every 5 seconds and renders a string into an `NSStatusItem`. That's
the whole app. The keys it uses:

| IOKit key | Used for |
|-----------|----------|
| `Voltage` (mV) × `Amperage` (mA) | Charging power in watts |
| `AdapterDetails → Watts` | Charger's max wattage |
| `AvgTimeToFull` (minutes) | Time until full |
| `AppleRawCurrentCapacity` / `AppleRawMaxCapacity` | Battery percentage |
| `ExternalConnected`, `IsCharging`, `FullyCharged` | Plugged-in / charging state |

The same data backs `pmset -g batt` and `system_profiler SPPowerDataType`, so the
numbers line up with what macOS reports elsewhere. All reads are **read-only**; the app
never writes to the registry, the filesystem (beyond its own bundle), or the network.

**Source:** it's one file — [`src/main.swift`](src/main.swift) (~140 lines of Swift + AppKit). Easy to read, fork, and tweak.

---

## 🖥️ Compatibility

- **macOS 12.0 (Monterey) or later**
- **Apple Silicon (M1/M2/M3/…) and Intel** — the released binary is universal.
- Works on MacBook Air / Pro. On desktops without a battery, the app simply won't show meaningful values.

> **Notch note:** the four-field readout is a bit of text. On a notched MacBook with a
> crowded menu bar it *could* get clipped near the notch. If that happens, open an issue —
> a compact display mode is an easy addition.

---

## 🔒 Privacy & Security

- **No network code.** The app makes zero connections. Verify it yourself: the source has no networking imports.
- **No data collection**, no analytics, no telemetry, no files written outside its own bundle.
- **Read-only hardware access** through public IOKit APIs — no elevated privileges, runs as your normal user.
- Distributed as source + a reproducible `build.sh`, so you can audit and rebuild rather than trusting a binary.

---

## ❓ FAQ / Troubleshooting

**"BatteryWatts is damaged and can't be opened" / "unidentified developer."**
That's Gatekeeper reacting to the ad-hoc signature on a browser-downloaded copy. Fix it with:
```sh
xattr -dr com.apple.quarantine ~/Applications/BatteryWatts.app
```
(The `curl | bash` installer already does this — this only happens with manual browser downloads.)

**The charging watts seem low.**
Expected — see the note near the top. Charging power ramps up when the battery is low and tapers as it fills; it rarely equals the charger's full rating.

**Nothing shows in the menu bar.**
Make sure it's running: `pgrep -x BatteryWatts`. If empty, launch it with
`open ~/Applications/BatteryWatts.app` or re-run the installer. On a Mac without a battery there's nothing to display.

**The time-to-full says `--:--`.**
macOS reports "still calculating" for a minute or two after you plug in. It'll fill in shortly.

**Does it drain my battery?**
Negligibly — it wakes briefly every 5 seconds to read a value and update text.

---

## 🤝 Contributing

Issues and pull requests are welcome! The whole app is one small Swift file, so it's a
friendly place to start. Ideas that would make great contributions:

- A compact / configurable display mode (choose which of the four fields to show).
- A menu option to toggle "start at login."
- Historical charging-rate graph in the dropdown.
- App icon + notarization for a warning-free first launch.

To hack on it: `./build.sh` to compile, then `open BatteryWatts.app` to try your changes.

---

## 📄 License

[MIT](LICENSE) — do whatever you like; attribution appreciated.

---

<div align="center">
<sub>Built for people who want to know what their charger is actually doing. ⚡</sub>
</div>
