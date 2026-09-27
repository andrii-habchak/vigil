import Foundation

/// Pure, UI-independent time helpers so the tricky bits (roll-to-tomorrow, remaining
/// formatting) can be unit-tested without touching `AppState` or the UI.
enum SessionMath {
    /// The next future instant whose hour/minute match `time`, per `calendar`.
    /// If today's occurrence has already passed, this returns tomorrow's.
    static func nextOccurrence(matching time: Date,
                               after now: Date,
                               calendar: Calendar = .current) -> Date {
        let comps = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.nextDate(after: now,
                                 matching: comps,
                                 matchingPolicy: .nextTime) ?? now
    }

    /// Compact remaining-time string for the menu bar, e.g. "2:05" or "9m".
    /// Returns nil when there's nothing meaningful left to show.
    static func menuBarRemaining(_ seconds: TimeInterval) -> String? {
        guard seconds > 0 else { return nil }
        let minutes = Int(ceil(seconds / 60))
        let h = minutes / 60
        let m = minutes % 60
        return h > 0 ? String(format: "%d:%02d", h, m) : "\(max(m, 1))m"
    }
}
