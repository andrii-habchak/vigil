import Testing

/// Phase 0 smoke test — proves the test target builds and runs.
/// Real coverage (schedule window calc, timer math, battery guard) arrives in Phase 4.
struct VigilTests {
    @Test func testTargetIsWired() {
        #expect(1 + 1 == 2)
    }
}
