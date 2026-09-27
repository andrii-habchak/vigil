import Foundation
import IOKit.pwr_mgt

/// Wraps an IOKit power assertion that prevents the display (and therefore the
/// system) from idle-sleeping. This also suppresses the screensaver and
/// lock-on-idle, since both are driven by the idle timer.
///
/// Uses `kIOPMAssertionTypePreventUserIdleDisplaySleep`: keeping the display awake
/// inherently keeps the system awake, which matches Vigil's "keep screen + system
/// awake" default.
final class PowerAssertionManager {
    private var assertionID: IOPMAssertionID = IOPMAssertionID(0)
    private(set) var isActive = false

    /// Create the assertion if not already held. Idempotent.
    func start(reason: String) {
        guard !isActive else { return }
        var id = IOPMAssertionID(0)
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &id
        )
        if result == kIOReturnSuccess {
            assertionID = id
            isActive = true
        }
    }

    /// Release the assertion if held. Idempotent.
    func stop() {
        guard isActive else { return }
        IOPMAssertionRelease(assertionID)
        assertionID = IOPMAssertionID(0)
        isActive = false
    }

    deinit { stop() }
}
