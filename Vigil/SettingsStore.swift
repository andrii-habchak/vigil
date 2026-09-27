import Foundation

/// Persists user settings in `UserDefaults`. Kept tiny and dependency-free so it can
/// be swapped for an in-memory instance in tests.
final class SettingsStore {
    private let defaults: UserDefaults
    private enum Key {
        static let schedule = "vigil.schedule"
        static let jiggleEnabled = "vigil.jiggleEnabled"
        static let jiggleInterval = "vigil.jiggleIntervalSeconds"
    }

    /// Default jiggle interval when nothing is stored yet.
    static let defaultJiggleInterval: Double = 30

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadSchedule() -> ScheduleModel {
        guard let data = defaults.data(forKey: Key.schedule),
              let model = try? JSONDecoder().decode(ScheduleModel.self, from: data) else {
            return ScheduleModel()
        }
        return model
    }

    func saveSchedule(_ model: ScheduleModel) {
        guard let data = try? JSONEncoder().encode(model) else { return }
        defaults.set(data, forKey: Key.schedule)
    }

    func loadJiggleEnabled() -> Bool {
        defaults.bool(forKey: Key.jiggleEnabled) // defaults to false when unset
    }

    func saveJiggleEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: Key.jiggleEnabled)
    }

    func loadJiggleInterval() -> Double {
        let stored = defaults.double(forKey: Key.jiggleInterval)
        return stored == 0 ? Self.defaultJiggleInterval : stored // 0 == unset
    }

    func saveJiggleInterval(_ seconds: Double) {
        defaults.set(seconds, forKey: Key.jiggleInterval)
    }
}
