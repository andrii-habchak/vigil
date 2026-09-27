import Testing

/// Tests for the low-battery pause/resume thresholds.
struct BatteryGuardLogicTests {
    private let threshold = 10

    // MARK: pause

    @Test func pausesOnBatteryAtThreshold() {
        #expect(BatteryGuardLogic.shouldPause(isOnAC: false, percentage: 10, threshold: threshold))
    }

    @Test func pausesOnBatteryBelowThreshold() {
        #expect(BatteryGuardLogic.shouldPause(isOnAC: false, percentage: 5, threshold: threshold))
    }

    @Test func doesNotPauseOnAC() {
        #expect(!BatteryGuardLogic.shouldPause(isOnAC: true, percentage: 5, threshold: threshold))
    }

    @Test func doesNotPauseAboveThreshold() {
        #expect(!BatteryGuardLogic.shouldPause(isOnAC: false, percentage: 11, threshold: threshold))
    }

    // MARK: resume

    @Test func resumesOnAC() {
        #expect(BatteryGuardLogic.shouldResume(isOnAC: true, percentage: 5, threshold: threshold))
    }

    @Test func resumesWhenAboveThreshold() {
        #expect(BatteryGuardLogic.shouldResume(isOnAC: false, percentage: 11, threshold: threshold))
    }

    @Test func doesNotResumeOnBatteryAtOrBelowThreshold() {
        #expect(!BatteryGuardLogic.shouldResume(isOnAC: false, percentage: 10, threshold: threshold))
        #expect(!BatteryGuardLogic.shouldResume(isOnAC: false, percentage: 3, threshold: threshold))
    }
}
