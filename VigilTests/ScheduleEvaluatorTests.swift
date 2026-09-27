import Testing
import Foundation

/// Tests for `ScheduleEvaluator`, including the tricky overnight-window case.
///
/// Reference dates use a fixed UTC calendar. Note: 2026-01-01 is a **Thursday**,
/// 2026-01-02 is a **Friday**.
struct ScheduleEvaluatorTests {

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func date(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int) -> Date {
        var comps = DateComponents()
        comps.year = y; comps.month = mo; comps.day = d; comps.hour = h; comps.minute = mi
        return utc.date(from: comps)!
    }

    private func model(enabled: Bool = true,
                       days: Set<Weekday>,
                       start: Int,
                       end: Int) -> ScheduleModel {
        var m = ScheduleModel()
        m.enabled = enabled
        m.days = days
        m.startMinutes = start
        m.endMinutes = end
        return m
    }

    // MARK: Same-day window

    @Test func activeInsideSameDayWindow() {
        let m = model(days: [.thursday], start: 9 * 60, end: 18 * 60)
        #expect(ScheduleEvaluator.isActive(m, at: date(2026, 1, 1, 12, 0), calendar: utc))
    }

    @Test func inactiveBeforeStart() {
        let m = model(days: [.thursday], start: 9 * 60, end: 18 * 60)
        #expect(!ScheduleEvaluator.isActive(m, at: date(2026, 1, 1, 8, 0), calendar: utc))
    }

    @Test func inactiveAtEndBoundary() {
        // End is exclusive: exactly 18:00 is no longer active.
        let m = model(days: [.thursday], start: 9 * 60, end: 18 * 60)
        #expect(!ScheduleEvaluator.isActive(m, at: date(2026, 1, 1, 18, 0), calendar: utc))
    }

    @Test func inactiveOnUnselectedDay() {
        let m = model(days: [.monday], start: 9 * 60, end: 18 * 60)
        #expect(!ScheduleEvaluator.isActive(m, at: date(2026, 1, 1, 12, 0), calendar: utc)) // Thu
    }

    // MARK: Overnight window (22:00–06:00)

    @Test func overnightActiveInTheEvening() {
        let m = model(days: [.thursday], start: 22 * 60, end: 6 * 60)
        #expect(ScheduleEvaluator.isActive(m, at: date(2026, 1, 1, 23, 0), calendar: utc)) // Thu 23:00
    }

    @Test func overnightActiveNextMorningWhenPriorDaySelected() {
        let m = model(days: [.thursday], start: 22 * 60, end: 6 * 60)
        // Fri 05:00 — belongs to Thursday's overnight window.
        #expect(ScheduleEvaluator.isActive(m, at: date(2026, 1, 2, 5, 0), calendar: utc))
    }

    @Test func overnightInactiveNextMorningWhenPriorDayNotSelected() {
        let m = model(days: [.friday], start: 22 * 60, end: 6 * 60)
        // Fri 05:00 — Thursday not selected, and Friday evening hasn't started.
        #expect(!ScheduleEvaluator.isActive(m, at: date(2026, 1, 2, 5, 0), calendar: utc))
    }

    // MARK: Guards

    @Test func inactiveWhenDisabled() {
        let m = model(enabled: false, days: [.thursday], start: 9 * 60, end: 18 * 60)
        #expect(!ScheduleEvaluator.isActive(m, at: date(2026, 1, 1, 12, 0), calendar: utc))
    }

    @Test func inactiveWhenNoDaysSelected() {
        let m = model(days: [], start: 9 * 60, end: 18 * 60)
        #expect(!ScheduleEvaluator.isActive(m, at: date(2026, 1, 1, 12, 0), calendar: utc))
    }

    @Test func inactiveWhenStartEqualsEnd() {
        let m = model(days: [.thursday], start: 9 * 60, end: 9 * 60)
        #expect(!ScheduleEvaluator.isActive(m, at: date(2026, 1, 1, 9, 0), calendar: utc))
    }
}
