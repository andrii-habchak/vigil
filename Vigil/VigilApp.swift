import SwiftUI
import AppKit

/// Vigil — a menu-bar utility that keeps the Mac awake and can jiggle the cursor.
///
/// Phase 0: bare menu-bar agent (no Dock icon) with a placeholder menu and Quit.
/// Keep-awake, session modes, schedule, jiggle, and battery guard land in later phases.
@main
struct VigilApp: App {
    var body: some Scene {
        MenuBarExtra("Vigil", systemImage: "eye") {
            Text("Vigil")
                .font(.headline)
            Text("Setup in progress — Phase 0")
                .foregroundStyle(.secondary)

            Divider()

            Button("Quit Vigil") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .menuBarExtraStyle(.menu)
    }
}
