import Foundation

/// A manual keep-awake mode chosen by the user. These are mutually exclusive:
/// starting one replaces any running manual session.
enum ManualMode: Equatable {
    /// Keep awake for a fixed number of hours (0.5h granularity).
    case duration(hours: Double)
    /// Keep awake until a specific wall-clock time.
    case until(Date)
    /// Keep awake until the user turns it off.
    case unlimited
}

/// A currently running manual session.
struct ActiveSession: Equatable {
    let mode: ManualMode
    /// When the session ends; `nil` for `.unlimited`.
    let endDate: Date?
    let startedAt: Date
}
