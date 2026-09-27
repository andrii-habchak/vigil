import SwiftUI

/// Single source of truth for Vigil's runtime state.
///
/// The Mac is kept awake when **either** a manual session is running **or** the weekly
/// schedule is in-window — unless the low-battery guard has paused everything. A single
/// `reconcile()` maps that decision onto one power assertion (and the jiggle), so
/// `isAwake` always reflects the real assertion.
@MainActor
final class AppState: ObservableObject {
    @Published private(set) var activeManualSession: ActiveSession?
    @Published private(set) var remaining: TimeInterval?
    @Published private(set) var scheduleActiveNow = false
    /// True when keep-awake is suspended because of low battery.
    @Published private(set) var batteryPaused = false

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

    /// Jiggle interval in seconds; persisted. The idle threshold tracks it.
    @Published var jiggleIntervalSeconds: Double {
        didSet {
            store.saveJiggleInterval(jiggleIntervalSeconds)
            jiggle.idleThreshold = jiggleIntervalSeconds
            jiggle.interval = jiggleIntervalSeconds
        }
    }

    /// Low-battery pause threshold (percent); persisted.
    @Published var batteryThreshold: Int {
        didSet {
            store.saveBatteryThreshold(batteryThreshold)
            evaluateBattery()
        }
    }

    /// Launch-at-login preference; persisted and applied to the system.
    @Published var launchAtLogin: Bool {
        didSet {
            store.saveLaunchAtLogin(launchAtLogin)
            loginItem.setEnabled(launchAtLogin)
        }
    }

    // Popover inputs (bound by the UI).
    @Published var durationHours: Double = 2.0
    @Published var untilTime: Date = Date().addingTimeInterval(3600)

    private let power = PowerAssertionManager()
    private let jiggle = JiggleController()
    private let battery = BatteryMonitor()
    private let loginItem = LoginItemManager()
    private let notifications = NotificationManager()
    private let store: SettingsStore
    private var countdownTicker: Timer?
    private var scheduleTicker: Timer?

    init(store: SettingsStore = SettingsStore()) {
        self.store = store
        self.schedule = store.loadSchedule()
        self.jiggleEnabled = store.loadJiggleEnabled()
        self.jiggleIntervalSeconds = store.loadJiggleInterval()
        self.batteryThreshold = store.loadBatteryThreshold()
        self.launchAtLogin = store.loadLaunchAtLogin()

        jiggle.interval = jiggleIntervalSeconds
        jiggle.idleThreshold = jiggleIntervalSeconds

        notifications.requestAuthorization()
        loginItem.syncOnLaunch(desired: launchAtLogin)

        battery.onChange = { [weak self] in
            MainActor.assumeIsolated { self?.evaluateBattery() }
        }
        battery.start()

        evaluateBattery()   // may set batteryPaused before the first reconcile
        evaluateSchedule()  // reconciles
        startScheduleTicker()
    }

    // MARK: - Derived state

    /// The real keep-awake state (reflects the actual power assertion).
    var isAwake: Bool { power.isActive }

    /// Whether a source wants keep-awake, before the battery guard is applied.
    private var desiredAwake: Bool { activeManualSession != nil || scheduleActiveNow }

    /// True when a source wants keep-awake but the battery guard has paused it.
    var isPausedForBattery: Bool { batteryPaused && desiredAwake }

    var statusText: String {
        if isPausedForBattery { return "Paused — low battery" }
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

    var menuBarSymbol: String {
        if isPausedForBattery { return "eye.slash" }
        return power.isActive ? "eye.fill" : "eye"
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
        refreshBatteryPause()   // apply the guard now that a source wants awake
        reconcile()

        // If not battery-paused and the assertion still didn't take, it genuinely
        // failed — don't keep a phantom session.
        if !batteryPaused && !power.isActive {
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
        refreshBatteryPause()   // a newly-active window must respect the battery guard
        reconcile()
    }

    private func startScheduleTicker() {
        let timer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.evaluateSchedule() }
        }
        RunLoop.main.add(timer, forMode: .common)
        scheduleTicker = timer
    }

    // MARK: - Battery guard

    /// Update `batteryPaused` (and fire transition notifications) *without* reconciling.
    /// Call this whenever `desiredAwake` may have just become true, then `reconcile()`,
    /// so the guard applies immediately rather than only on the next power event.
    private func refreshBatteryPause() {
        let snapshot = battery.snapshot()
        guard snapshot.hasBattery, let percentage = snapshot.percentage else {
            // No battery (desktop): never pause; clear any stale pause.
            if batteryPaused { batteryPaused = false }
            return
        }

        if batteryPaused {
            if BatteryGuardLogic.shouldResume(isOnAC: snapshot.isOnAC,
                                              percentage: percentage,
                                              threshold: batteryThreshold) {
                batteryPaused = false
                if desiredAwake {
                    notifications.post(title: "Vigil resumed",
                                       body: "Power restored — keeping your Mac awake again.")
                }
            }
        } else if desiredAwake,
                  BatteryGuardLogic.shouldPause(isOnAC: snapshot.isOnAC,
                                                percentage: percentage,
                                                threshold: batteryThreshold) {
            batteryPaused = true
            notifications.post(title: "Vigil paused",
                               body: "Battery at \(percentage)% — paused to save power. "
                                   + "It resumes when you plug in.")
        }
    }

    /// Battery refresh from change events / threshold edits (updates + reconciles).
    private func evaluateBattery() {
        refreshBatteryPause()
        reconcile()
    }

    // MARK: - Reconciliation

    private func reconcile() {
        let effective = KeepAwakeDecision.effectiveAwake(
            manualActive: activeManualSession != nil,
            scheduleActive: scheduleActiveNow,
            batteryPaused: batteryPaused
        )
        if effective {
            power.start(reason: "Vigil keeping the Mac awake")
        } else {
            power.stop()
        }
        reconcileJiggle()
    }

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
            activeManualSession = nil
            remaining = nil
            stopCountdownTicker()
            reconcile()
            notifications.post(title: "Vigil", body: "Your timed session has ended.")
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
