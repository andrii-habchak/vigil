import Foundation

/// Pure decision helper for the cursor jiggle, kept separate so the idle-vs-active
/// rule can be unit-tested (an inverted comparison here would make the jiggle fight
/// active input instead of only nudging while idle).
enum JiggleMath {
    /// Nudge the cursor only once the user has been idle for at least `threshold`.
    static func shouldJiggle(idleSeconds: TimeInterval, threshold: TimeInterval) -> Bool {
        idleSeconds >= threshold
    }
}
