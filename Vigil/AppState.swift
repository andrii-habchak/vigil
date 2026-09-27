import SwiftUI

/// Single source of truth for Vigil's runtime state.
///
/// The Mac is kept awake when **either** a manual session is running **or** the weekly
/// schedule is currently in-window. A single `reconcile()` maps that desired state onto
/// the one power assertion, so `isAwake` always reflects the real assertion.
@MainActor
final class AppState: ObservableObject {
    /// The running manual session, or nil when no manual session is active.
    @Published private(set) var activeManualSession: ActiveSession?
    /// Seconds remaining for a timed manual session; nil otherwise.
    @Published private(set) var remaining: TimeInterval?
    /// Whether the schedule is currently within an active window.
    @Published private(set) var scheduleActiveNow: Bool = false

    /// The weekly schedule; persisted on every change.
    @Published var schedule: ScheduleModel {
        didSet { onScheduleChanged() }
    }

    /// Whether the cursor jiggle is enabled; persisted. Active only while awake.
    @Published var jiggleEnabled: Bool {
        didSet {
            store.saveJiggleEnabled(jiggleEnabled)
            reconcileJiggle()
        }
    }

    /// Jiggle check interval in seconds; persisted.
    @Published var jiggleIntervalSeconds: Double {
        didSet {
            store.saveJiggleInterval(jiggleIntervalSeconds)
            jiggle.interval = jiggleIntervalSeconds
        }
    }

    // Popover inputs (bound by the UI).
    @Published var durationHours: Double = 2.0
    @Published var untilTime: Date = Date().addingTimeInterval(3600)

    private let power = PowerAssertionManager()
    private let jiggle = JiggleController()
    private let store: SettingsStore
    private var countdownTicker: Timer?
    private var scheduleTicker: Timer?

    init(store: SettingsStore = SettingsStore()) {
        self.store = store
        self.schedule = store.loadSchedule()
        self.jiggleEnabled = store.loadJiggleEnabled()
        self.jiggleIntervalSeconds = store.loadJiggleInterval()
        jiggle.interval = jiggleIntervalSeconds
        evaluateSchedule()
        startScheduleTicker()
    }

    // MARK: - Derived state

    /// The real keep-awake state (reflects the actual power assertion).
    var isAwake: Bool { power.isActive }

    /// Whether the app *wants* to be awake, before the assertion is applied.
    private var desiredAwake: Bool { activeManualSession != nil || scheduleActiveNow }

    var statusText: String {
        guard power.isActive else { return "Off" }
        if let session = activeManualSession {
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
        if scheduleActiveNow { return "On — schedule" }
        return "On"
    }

    var menuBarRemaining: String? {
        guard let remaining else { return nil }
        return SessionMath.menuBarRemaining(remaining)
    }

    // MARK: - Manual sessions

    func startUnlimited() {
        beginManual(mode: .unlimited, end: nil)
    }

    func startDuration() {
        let hours = max(0.5, durationHours)
        beginManual(mode: .duration(hours: hours), end: Date().addingTimeInterval(hours * 3600))
    }

    func startUntil() {
        let end = SessionMath.nextOccurrence(matching: untilTime, after: Date())
        beginManual(mode: .until(end), end: end)
    }

    /// Stop the manual session. Keep-awake continues if the schedule is still in-window.
    func stopManual() {
        activeManualSession = nil
        remaining = nil
        stopCountdownTicker()
        reconcile()
    }

    private func beginManual(mode: ManualMode, end: Date?) {
        activeManualSession = ActiveSession(mode: mode, endDate: end, startedAt: Date())
        if end == nil {
            remaining = nil
            stopCountdownTicker()
        } else {
            startCountdownTicker()
            updateRemaining()
        }
        reconcile()

        // If the assertion could not be created, don't keep a phantom session.
        if !power.isActive {
            activeManualSession = nil
            remaining = nil
            stopCountdownTicker()
        }
    }

    // MARK: - Schedule

    private func onScheduleChanged() {
        store.saveSchedule(schedule)
        evaluateSchedule()
    }

    private func evaluateSchedule() {
        let active = ScheduleEvaluator.isActive(schedule, at: Date())
        if active != scheduleActiveNow {
            scheduleActiveNow = active
        }
        reconcile()
    }

    private func startScheduleTicker() {
        let timer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.evaluateSchedule() }
        }
        RunLoop.main.add(timer, forMode: .common)
        scheduleTicker = timer
    }

    // MARK: - Power reconciliation

    /// Bring the single power assertion in line with `desiredAwake`, then the jiggle.
    private func reconcile() {
        if desiredAwake {
            power.start(reason: "Vigil keeping the Mac awake")
        } else {
            power.stop()
        }
        reconcileJiggle()
    }

    /// Run the jiggle only while actually awake and enabled.
    private func reconcileJiggle() {
        if power.isActive && jiggleEnabled {
            jiggle.start()
        } else {
            jiggle.stop()
        }
    }

    // MARK: - Countdown

    private func startCountdownTicker() {
        stopCountdownTicker()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.updateRemaining() }
        }
        RunLoop.main.add(timer, forMode: .common)
        countdownTicker = timer
    }

    private func stopCountdownTicker() {
        countdownTicker?.invalidate()
        countdownTicker = nil
    }

    private func updateRemaining() {
        guard let session = activeManualSession, let end = session.endDate else {
            remaining = nil
            return
        }
        let left = end.timeIntervalSinceNow
        if left <= 0 {
            stopManual()
            return
        }
        remaining = left
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
