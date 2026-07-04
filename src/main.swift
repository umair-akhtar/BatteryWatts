import Cocoa
import IOKit
import IOKit.ps

// MARK: - Battery reading

struct BatteryInfo {
    var pluggedIn: Bool = false
    var charging: Bool = false
    var fullyCharged: Bool = false
    var percent: Int = 0
    var chargeWatts: Double = 0      // power flowing into the battery (V * I)
    var adapterWatts: Int = 0        // adapter's max rating
    var minutesToFull: Int = -1      // -1 = unknown / not charging
}

func readBattery() -> BatteryInfo {
    var info = BatteryInfo()

    let matching = IOServiceMatching("AppleSmartBattery")
    let service = IOServiceGetMatchingService(kIOMainPortDefault, matching)
    guard service != 0 else { return info }
    defer { IOObjectRelease(service) }

    var propsRef: Unmanaged<CFMutableDictionary>?
    guard IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0) == KERN_SUCCESS,
          let props = propsRef?.takeRetainedValue() as? [String: Any] else {
        return info
    }

    info.pluggedIn = (props["ExternalConnected"] as? Bool) ?? false
    info.charging = (props["IsCharging"] as? Bool) ?? false
    info.fullyCharged = (props["FullyCharged"] as? Bool) ?? false

    // State of charge
    if let raw = props["AppleRawCurrentCapacity"] as? Int,
       let rawMax = props["AppleRawMaxCapacity"] as? Int, rawMax > 0 {
        info.percent = Int((Double(raw) / Double(rawMax) * 100).rounded())
    } else if let cur = props["CurrentCapacity"] as? Int {
        info.percent = cur
    }

    // Charge power into the battery: Voltage(mV) * Amperage(mA)
    if let mV = props["Voltage"] as? Int, let mA = props["Amperage"] as? Int {
        let watts = (Double(mV) / 1000.0) * (Double(mA) / 1000.0)
        info.chargeWatts = max(0, watts)   // negative = discharging
    }

    // Adapter max rating
    if let adapter = props["AdapterDetails"] as? [String: Any],
       let watts = adapter["Watts"] as? Int {
        info.adapterWatts = watts
    }

    // Time to full (minutes). 65535 means "still calculating".
    if let t = props["AvgTimeToFull"] as? Int, t >= 0, t < 65535 {
        info.minutesToFull = t
    }

    return info
}

func formatTime(_ minutes: Int) -> String {
    let h = minutes / 60
    let m = minutes % 60
    return String(format: "%d:%02d", h, m)
}

// MARK: - App

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        }
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func refresh() {
        let b = readBattery()

        // Status-bar title: charging watts · charger watts · time to full · battery %
        let title: String
        let chargeW = String(format: "%.0f", b.chargeWatts)
        let adapterW = b.adapterWatts > 0 ? "\(b.adapterWatts)" : "—"
        if !b.pluggedIn {
            title = "🔋 \(b.percent)%"
        } else if b.fullyCharged || (b.percent >= 100) {
            title = "⚡ \(chargeW)/\(adapterW)W · Full · \(b.percent)%"
        } else {
            let eta = b.minutesToFull >= 0 ? formatTime(b.minutesToFull) : "--:--"
            title = "⚡ \(chargeW)/\(adapterW)W · \(eta) · \(b.percent)%"
        }
        statusItem.button?.title = title

        // Dropdown detail menu
        let menu = NSMenu()
        if b.pluggedIn {
            if b.fullyCharged {
                menu.addItem(makeInfo("Status: Fully charged"))
            } else if b.chargeWatts >= 0.5 {
                menu.addItem(makeInfo(String(format: "Charging at: %.1f W", b.chargeWatts)))
            } else {
                menu.addItem(makeInfo("Status: Plugged in (not charging)"))
            }
            if b.adapterWatts > 0 {
                menu.addItem(makeInfo("Adapter: \(b.adapterWatts) W max"))
            }
            if b.minutesToFull >= 0 && !b.fullyCharged {
                menu.addItem(makeInfo("Time until full: \(formatTime(b.minutesToFull))"))
            }
        } else {
            menu.addItem(makeInfo("On battery power"))
        }
        menu.addItem(makeInfo("Battery: \(b.percent)%"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit BatteryWatts", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    func makeInfo(_ text: String) -> NSMenuItem {
        let item = NSMenuItem(title: text, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)   // menu-bar only, no Dock icon
app.run()
