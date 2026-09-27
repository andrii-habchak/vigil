import Foundation
import IOKit.ps

/// Reads the current power-source state and notifies on changes (plug/unplug, level).
/// On a machine with no battery (desktop) it reports "on AC, no battery", so the
/// battery guard never pauses.
final class BatteryMonitor {
    struct Snapshot {
        let isOnAC: Bool
        let percentage: Int?
        let hasBattery: Bool
    }

    /// Called on the main run loop whenever the power source changes.
    var onChange: (() -> Void)?

    private var runLoopSource: CFRunLoopSource?

    func start() {
        let context = Unmanaged.passUnretained(self).toOpaque()
        let callback: IOPowerSourceCallbackType = { rawContext in
            guard let rawContext else { return }
            let monitor = Unmanaged<BatteryMonitor>.fromOpaque(rawContext).takeUnretainedValue()
            monitor.onChange?()
        }
        guard let source = IOPSNotificationCreateRunLoopSource(callback, context)?.takeRetainedValue() else {
            return
        }
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }
    }

    func snapshot() -> Snapshot {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef],
              let source = list.first,
              let desc = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any]
        else {
            // No battery (e.g. desktop) → treat as permanently on AC.
            return Snapshot(isOnAC: true, percentage: nil, hasBattery: false)
        }

        let state = desc[kIOPSPowerSourceStateKey as String] as? String
        let isOnAC = (state == (kIOPSACPowerValue as String))

        let current = desc[kIOPSCurrentCapacityKey as String] as? Int
        let maxCapacity = desc[kIOPSMaxCapacityKey as String] as? Int ?? 100
        let percentage = current.map { maxCapacity > 0 ? Int((Double($0) / Double(maxCapacity)) * 100.0) : $0 }

        return Snapshot(isOnAC: isOnAC, percentage: percentage, hasBattery: true)
    }

    deinit { stop() }
}
