import Testing

/// Tests for the manual-OR-schedule decision plus battery-pause precedence.
struct KeepAwakeDecisionTests {
    @Test func awakeWhenManualOnly() {
        #expect(KeepAwakeDecision.effectiveAwake(manualActive: true, scheduleActive: false, batteryPaused: false))
    }

    @Test func awakeWhenScheduleOnly() {
        #expect(KeepAwakeDecision.effectiveAwake(manualActive: false, scheduleActive: true, batteryPaused: false))
    }

    @Test func awakeWhenBoth() {
        #expect(KeepAwakeDecision.effectiveAwake(manualActive: true, scheduleActive: true, batteryPaused: false))
    }

    @Test func offWhenNeither() {
        #expect(!KeepAwakeDecision.effectiveAwake(manualActive: false, scheduleActive: false, batteryPaused: false))
    }

    @Test func batteryPauseOverridesManual() {
        #expect(!KeepAwakeDecision.effectiveAwake(manualActive: true, scheduleActive: false, batteryPaused: true))
    }

    @Test func batteryPauseOverridesSchedule() {
        #expect(!KeepAwakeDecision.effectiveAwake(manualActive: false, scheduleActive: true, batteryPaused: true))
    }
}
