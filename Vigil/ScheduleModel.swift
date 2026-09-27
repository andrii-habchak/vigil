import Foundation

/// The weekly schedule: selected days plus one shared start–end time window applied
/// to all of them. Times are stored as minutes-from-midnight for stable persistence
/// and easy comparison.
struct ScheduleModel: Codable, Equatable {
    var enabled: Bool = false
    var days: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    var startMinutes: Int = 9 * 60    // 09:00
    var endMinutes: Int = 18 * 60     // 18:00

    /// True when the window crosses midnight (e.g. 22:00–06:00).
    var isOvernight: Bool { endMinutes <= startMinutes }

    var daysText: String {
        Weekday.displayOrder.filter { days.contains($0) }.map(\.shortName).joined(separator: " ")
    }

    var timeWindowText: String {
        "\(Self.hhmm(startMinutes))–\(Self.hhmm(endMinutes))"
    }

    static func hhmm(_ minutes: Int) -> String {
        String(format: "%02d:%02d", (minutes / 60) % 24, minutes % 60)
    }
}
