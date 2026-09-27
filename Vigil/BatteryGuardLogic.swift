import Foundation

/// Pure transition logic for the low-battery guard, so the pause/resume thresholds
/// can be unit-tested independently of IOKit.
enum BatteryGuardLogic {
    /// Pause keep-awake when running on battery at or below the threshold.
    static func shouldPause(isOnAC: Bool, percentage: Int, threshold: Int) -> Bool {
        !isOnAC && percentage <= threshold
    }

    /// Resume once power is back or the level has risen above the threshold.
    static func shouldResume(isOnAC: Bool, percentage: Int, threshold: Int) -> Bool {
        isOnAC || percentage > threshold
    }
}
