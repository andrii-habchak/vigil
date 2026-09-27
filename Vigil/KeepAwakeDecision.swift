import Foundation

/// Pure decision for whether Vigil should currently hold the power assertion.
/// Keeping this as a free function makes the OR-of-sources plus battery-pause
/// precedence unit-testable without the stateful `AppState`.
enum KeepAwakeDecision {
    /// Awake when a manual session OR the schedule wants it, unless the battery
    /// guard has paused everything.
    static func effectiveAwake(manualActive: Bool,
                               scheduleActive: Bool,
                               batteryPaused: Bool) -> Bool {
        (manualActive || scheduleActive) && !batteryPaused
    }
}
