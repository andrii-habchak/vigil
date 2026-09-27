import SwiftUI

/// Single source of truth for Vigil's runtime state.
///
/// Phase 1 scope: manual keep-awake sessions (unlimited / duration / until) driving a
/// single IOKit power assertion, plus the derived text/icon the UI shows. Schedule,
/// jiggle, and battery guard are layered on in later phases.
@MainActor
final class AppState: ObservableObject {
    /// The running manual session, or nil when Vigil is off.
    @Published private(set) var activeSession: ActiveSession?
    /// Seconds remaining for a timed session; nil for unlimited/off.
    @Published private(set) var remaining: TimeInterval?

    // Popover inputs (bound by the UI).
    @Published var durationHours: Double = 2.0
    @Published var untilTime: Date = Date().addingTimeInterval(3600)

    private let power = PowerAssertionManager()
    private var ticker: Timer?

    var isAwake: Bool { activeSession != nil }

    /// Human-readable status for the popover header.
    var statusText: String {
        guard let session = activeSession else { return "Off" }
        switch session.mode {
        case .unlimited:
            return "On — unlimited"
        case .duration, .until:
            if let end = session.endDate {
                return "On — until \(Self.timeFormatter.string(from: end))"
            }
            return "On"
        }
    }

    /// Compact remaining string for the menu-bar label, or nil when nothing to show.
    var menuBarRemaining: String? {
        guard let remaining else { return nil }
        return SessionMath.menuBarRemaining(remaining)
    }

    // MARK: - Start / stop

    func startUnlimited() {
        begin(mode: .unlimited, end: nil)
    }

    func startDuration() {
        let hours = max(0.5, durationHours)
        begin(mode: .duration(hours: hours), end: Date().addingTimeInterval(hours * 3600))
    }

    func startUntil() {
        let end = SessionMath.nextOccurrence(matching: untilTime, after: Date())
        begin(mode: .until(end), end: end)
    }

    func stop() {
        activeSession = nil
        remaining = nil
        power.stop()
        stopTicker()
    }

    // MARK: - Internals

    private func begin(mode: ManualMode, end: Date?) {
        activeSession = ActiveSession(mode: mode, endDate: end, startedAt: Date())
        power.start(reason: "Vigil keeping the Mac awake")
        startTicker()
        tick()
    }

    private func startTicker() {
        stopTicker()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    private func tick() {
        guard let session = activeSession else { return }
        if let end = session.endDate {
            let left = end.timeIntervalSinceNow
            if left <= 0 {
                stop()
                return
            }
            remaining = left
        } else {
            remaining = nil
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
