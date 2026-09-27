import SwiftUI

/// Vigil — a menu-bar utility that keeps the Mac awake and can jiggle the cursor.
@main
struct VigilApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
                .environmentObject(state)
        } label: {
            // Icon reflects state; timed sessions also show remaining time.
            if let remaining = state.menuBarRemaining {
                Label(remaining, systemImage: state.isAwake ? "eye.fill" : "eye")
            } else {
                Image(systemName: state.isAwake ? "eye.fill" : "eye")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
