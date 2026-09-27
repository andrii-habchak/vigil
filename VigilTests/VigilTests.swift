import Testing
import Foundation

/// Tests for the pure time helpers in `SessionMath` (compiled into this target).
struct SessionMathTests {

    /// Deterministic UTC calendar so date math doesn't depend on the machine locale/DST.
    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        comps.hour = hour; comps.minute = minute
        return utc.date(from: comps)!
    }

    // MARK: nextOccurrence (roll-to-tomorrow)

    @Test func untilRollsToTomorrowWhenTimeAlreadyPassed() {
        let now = date(2026, 1, 1, 20, 0)      // 20:00
        let picked = date(2026, 1, 1, 18, 0)   // 18:00 already passed today
        let result = SessionMath.nextOccurrence(matching: picked, after: now, calendar: utc)
        #expect(result == date(2026, 1, 2, 18, 0))
    }

    @Test func untilStaysTodayWhenTimeIsStillAhead() {
        let now = date(2026, 1, 1, 10, 0)      // 10:00
        let picked = date(2026, 1, 1, 18, 0)   // 18:00 still ahead
        let result = SessionMath.nextOccurrence(matching: picked, after: now, calendar: utc)
        #expect(result == date(2026, 1, 1, 18, 0))
    }

    // MARK: menuBarRemaining formatting

    @Test func remainingFormatsHoursAndMinutes() {
        #expect(SessionMath.menuBarRemaining(2 * 3600) == "2:00")
        #expect(SessionMath.menuBarRemaining(90 * 60) == "1:30")
        #expect(SessionMath.menuBarRemaining(3600) == "1:00")
    }

    @Test func remainingFormatsMinutesUnderAnHour() {
        #expect(SessionMath.menuBarRemaining(59 * 60) == "59m")
        #expect(SessionMath.menuBarRemaining(25 * 60) == "25m")
        #expect(SessionMath.menuBarRemaining(30) == "1m") // rounds up, floor of 1m
    }

    @Test func remainingIsNilWhenNonPositive() {
        #expect(SessionMath.menuBarRemaining(0) == nil)
        #expect(SessionMath.menuBarRemaining(-5) == nil)
    }
}
