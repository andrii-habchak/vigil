import SwiftUI
import AppKit

/// The popover shown when the user clicks Vigil's menu-bar icon (`.window` style).
struct MenuContentView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            Divider()

            if state.isPausedForBattery {
                pausedBanner
            }

            if state.activeManualSession != nil {
                activeControls
            } else {
                if state.scheduleActiveNow && !state.isPausedForBattery {
                    scheduleBanner
                }
                idleControls
            }

            Divider()

            jiggleToggle

            Divider()

            footer
        }
        .padding(14)
        .frame(width: 280)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: state.isAwake ? "eye.fill" : "eye.slash")
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
            state.stopManual()
        } label: {
            Label("Turn off", systemImage: "stop.circle")
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private var pausedBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "battery.25")
                .foregroundStyle(.orange)
            Text("Paused — low battery. Resumes when you plug in.")
                .font(.caption)
            Spacer()
        }
        .padding(8)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var scheduleBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar.badge.clock")
                .foregroundStyle(Color.accentColor)
            Text("Awake by schedule (\(state.schedule.timeWindowText))")
                .font(.caption)
            Spacer()
        }
        .padding(8)
        .background(Color.accentColor.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 6))
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

    private var jiggleToggle: some View {
        Toggle(isOn: $state.jiggleEnabled) {
            Label("Jiggle cursor while awake", systemImage: "cursorarrow.motionlines")
        }
        .toggleStyle(.switch)
        .font(.callout)
    }

    private var footer: some View {
        HStack {
            Button("Settings…") { openSettings() }
            Spacer()
            Button("Quit Vigil") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }

    private func openSettings() {
        openWindow(id: "settings")
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private var durationLabel: String {
        let hours = state.durationHours
        if hours == hours.rounded() {
            return "\(Int(hours)) h"
        }
        return String(format: "%.1f h", hours)
    }
}
