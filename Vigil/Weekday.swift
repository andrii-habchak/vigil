import Foundation

/// A day of the week. Raw values match `Calendar`'s `weekday` component
/// (1 = Sunday … 7 = Saturday) so conversion is direct.
enum Weekday: Int, CaseIterable, Codable, Identifiable, Comparable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }

    /// UI display order (Monday first).
    static let displayOrder: [Weekday] = [
        .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
    ]

    /// The day before this one (wraps Sunday → Saturday).
    func previous() -> Weekday {
        Weekday(rawValue: rawValue == Weekday.sunday.rawValue ? Weekday.saturday.rawValue : rawValue - 1)!
    }

    static func < (lhs: Weekday, rhs: Weekday) -> Bool { lhs.rawValue < rhs.rawValue }
}
