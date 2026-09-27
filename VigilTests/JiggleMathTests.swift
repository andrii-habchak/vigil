import Testing
import Foundation

/// Tests for the jiggle idle-vs-active decision.
struct JiggleMathTests {
    @Test func jigglesWhenIdleAtOrAboveThreshold() {
        #expect(JiggleMath.shouldJiggle(idleSeconds: 25, threshold: 25))
        #expect(JiggleMath.shouldJiggle(idleSeconds: 40, threshold: 25))
    }

    @Test func doesNotJiggleWhileActive() {
        #expect(!JiggleMath.shouldJiggle(idleSeconds: 5, threshold: 25))
        #expect(!JiggleMath.shouldJiggle(idleSeconds: 24.9, threshold: 25))
    }
}
