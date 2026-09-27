import SwiftUI

/// The Settings window: the weekly-schedule editor (days + one shared time window).
struct SettingsView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        Form {
            Section {
                Toggle("Enable weekly schedule", isOn: $state.schedule.enabled)
            } footer: {
                Text("When enabled, Vigil keeps the Mac awake during the days and time "
                     + "window below — in addition to any manual session.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Days") {
                HStack(spacing: 6) {
                    ForEach(Weekday.displayOrder) { day in
                        dayToggle(day)
                    }
                }
                .disabled(!state.schedule.enabled)
            }

            Section("Time window") {
                DatePicker("Start", selection: startBinding, displayedComponents: .hourAndMinute)
                DatePicker("End", selection: endBinding, displayedComponents: .hourAndMinute)
                if state.schedule.isEmptyWindow {
                    Label("Start and end are the same — this window never activates.",
                          systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if state.schedule.isOvernight {
                    Label("Overnight window — it ends the following morning.",
                          systemImage: "moon.stars")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(!state.schedule.enabled)

            Section {
                Toggle("Jiggle the cursor while awake", isOn: $state.jiggleEnabled)
                Stepper(value: $state.jiggleIntervalSeconds, in: 10...300, step: 5) {
                    Text("Check every \(Int(state.jiggleIntervalSeconds))s")
                }
                .disabled(!state.jiggleEnabled)
            } header: {
                Text("Cursor jiggle")
            } footer: {
                Text("While Vigil is keeping the Mac awake and you've been idle, it nudges "
                     + "the cursor 1px so pointer activity is registered. It never moves the "
                     + "cursor while you're actively using it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 480)
    }

    private func dayToggle(_ day: Weekday) -> some View {
        let isOn = state.schedule.days.contains(day)
        return Button {
            if isOn {
                state.schedule.days.remove(day)
            } else {
                state.schedule.days.insert(day)
            }
        } label: {
            Text(day.shortName)
                .font(.caption.weight(.medium))
                .frame(width: 40, height: 30)
                .background(isOn ? Color.accentColor : Color.secondary.opacity(0.15))
                .foregroundStyle(isOn ? Color.white : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    // MARK: Minutes <-> Date bridging for the time pickers

    private var startBinding: Binding<Date> {
        Binding(
            get: { Self.date(fromMinutes: state.schedule.startMinutes) },
            set: { state.schedule.startMinutes = Self.minutes(from: $0) }
        )
    }

    private var endBinding: Binding<Date> {
        Binding(
            get: { Self.date(fromMinutes: state.schedule.endMinutes) },
            set: { state.schedule.endMinutes = Self.minutes(from: $0) }
        )
    }

    private static func date(fromMinutes minutes: Int) -> Date {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .minute, value: minutes, to: base) ?? base
    }

    private static func minutes(from date: Date) -> Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }
}
