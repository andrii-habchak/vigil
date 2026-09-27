import Foundation

/// Decides whether the weekly schedule says "keep awake" at a given instant.
/// Handles both same-day windows (09:00–18:00) and overnight windows that wrap
/// past midnight (22:00–06:00).
enum ScheduleEvaluator {
    static func isActive(_ model: ScheduleModel,
                         at date: Date,
                         calendar: Calendar = .current) -> Bool {
        guard model.enabled,
              !model.days.isEmpty,
              model.startMinutes != model.endMinutes else {
            return false
        }

        let comps = calendar.dateComponents([.weekday, .hour, .minute], from: date)
        guard let weekdayRaw = comps.weekday, let today = Weekday(rawValue: weekdayRaw) else {
            return false
        }
        let nowMinutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)

        if model.startMinutes < model.endMinutes {
            // Same-day window: [start, end) on a selected day.
            return model.days.contains(today)
                && nowMinutes >= model.startMinutes
                && nowMinutes < model.endMinutes
        } else {
            // Overnight window: it opens at `start` on a selected day and closes at
            // `end` the next morning.
            //   - evening part: today is selected and we're at/after start
            //   - morning part: yesterday was selected and we're before end
            let eveningPart = model.days.contains(today) && nowMinutes >= model.startMinutes
            let morningPart = model.days.contains(today.previous()) && nowMinutes < model.endMinutes
            return eveningPart || morningPart
        }
    }
}
