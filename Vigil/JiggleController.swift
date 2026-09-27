import Foundation
import CoreGraphics

/// Periodically nudges the cursor 1px and back while the user is idle, so pointer
/// activity is registered. Uses `CGWarpMouseCursorPosition`, which needs no special
/// permission. It only nudges when the user has been idle, so it never fights active
/// input. (A synthetic-event mode behind an Accessibility opt-in can be added later if
/// warping proves insufficient at resetting idle timers.)
@MainActor
final class JiggleController {
    /// How often to check/nudge.
    var interval: TimeInterval = 30 {
        didSet {
            guard interval != oldValue, isRunning else { return }
            timer?.invalidate()
            scheduleTimer()
        }
    }
    /// Minimum idle time before a nudge is allowed.
    var idleThreshold: TimeInterval = 25

    private(set) var isRunning = false
    private var timer: Timer?

    func start() {
        guard !isRunning else { return }
        isRunning = true
        scheduleTimer()
    }

    func stop() {
        guard isRunning else { return }
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    private func scheduleTimer() {
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick() {
        guard JiggleMath.shouldJiggle(idleSeconds: systemIdleSeconds(),
                                      threshold: idleThreshold) else { return }
        jiggleOnce()
    }

    /// Seconds since the most recent user input event of any kind.
    private func systemIdleSeconds() -> TimeInterval {
        let inputTypes: [CGEventType] = [
            .mouseMoved, .leftMouseDown, .rightMouseDown, .otherMouseDown,
            .leftMouseDragged, .rightMouseDragged,
            .keyDown, .flagsChanged, .scrollWheel
        ]
        let seconds = inputTypes.map {
            CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0)
        }
        return seconds.min() ?? .greatestFiniteMagnitude
    }

    private func jiggleOnce() {
        guard let current = CGEvent(source: nil)?.location else { return }
        CGWarpMouseCursorPosition(CGPoint(x: current.x + 1, y: current.y))
        CGWarpMouseCursorPosition(current)
    }
}
