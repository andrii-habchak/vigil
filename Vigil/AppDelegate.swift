import AppKit

/// Ensures only one Vigil runs at a time. If another instance (any copy sharing the
/// bundle id) is already running, this one activates the existing instance and quits
/// immediately — before `AppState` creates power assertions or touches the login item.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        let bundleID = Bundle.main.bundleIdentifier ?? "io.github.andrii-habchak.Vigil"
        let current = NSRunningApplication.current
        let others = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleID)
            .filter { $0.processIdentifier != current.processIdentifier }

        if let existing = others.first {
            existing.activate()
            NSApp.terminate(nil)
        }
    }
}
