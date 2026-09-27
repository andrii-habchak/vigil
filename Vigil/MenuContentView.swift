import SwiftUI
import AppKit

/// The popover shown when the user clicks Vigil's menu-bar icon (`.window` style).
struct MenuContentView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            Divider()

            if state.isAwake {
                activeControls
            } else {
                idleControls
            }

            Divider()

            HStack {
                Spacer()
                Button("Quit Vigil") { NSApplication.shared.terminate(nil) }
                    .keyboardShortcut("q")
            }
        }
        .padding(14)
        .frame(width: 280)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: state.isAwake ? "eye.fill" : "eye")
                .font(.title3)
                .foregroundStyle(state.isAwake ? Color.accentColor : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Vigil").font(.headline)
                Text(state.statusText).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var activeControls: some View {
        Button {
            state.stop()
        } label: {
            Label("Turn off", systemImage: "stop.circle")
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private var idleControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                state.startUnlimited()
            } label: {
                Label("Keep awake — unlimited", systemImage: "infinity")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .controlSize(.large)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("For a set time").font(.caption).foregroundStyle(.secondary)
                Stepper(value: $state.durationHours, in: 0.5...24, step: 0.5) {
                    Text(durationLabel)
                }
                Button("Start") { state.startDuration() }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Until a time").font(.caption).foregroundStyle(.secondary)
                DatePicker("", selection: $state.untilTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                Button("Start") { state.startUntil() }
            }
        }
    }

    private var durationLabel: String {
        let hours = state.durationHours
        if hours == hours.rounded() {
            return "\(Int(hours)) h"
        }
        return String(format: "%.1f h", hours)
    }
}
