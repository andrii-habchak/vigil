import SwiftUI

/// Vigil — a menu-bar utility that keeps the Mac awake and can jiggle the cursor.
@main
struct VigilApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var state = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
                .environmentObject(state)
        } label: {
            // Icon reflects state (awake / off / battery-paused); timed sessions
            // also show remaining time.
            if let remaining = state.menuBarRemaining {
                Label(remaining, systemImage: state.menuBarSymbol)
            } else {
                Image(systemName: state.menuBarSymbol)
            }
        }
        .menuBarExtraStyle(.window)

        Window("Vigil Settings", id: "settings") {
            SettingsView()
                .environmentObject(state)
        }
        .windowResizability(.contentSize)
    }
}
