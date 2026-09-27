import Foundation
import ServiceManagement

/// Manages Vigil's "launch at login" state via `SMAppService`.
final class LoginItemManager {
    var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    /// Register/unregister the login item. Failures are swallowed (best-effort; the
    /// user can retry from Settings).
    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            NSLog("Vigil: login item update failed: \(error.localizedDescription)")
        }
    }

    /// Bring the system state in line with the persisted preference at launch.
    func syncOnLaunch(desired: Bool) {
        setEnabled(desired)
    }
}
