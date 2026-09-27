# Vigil — Requirements

## 1. Overview

Vigil is a native macOS menu-bar utility that keeps the Mac awake (prevents display +
system idle sleep, screensaver, and lock-on-idle) and can optionally jiggle the cursor.
It is a modern, minimal analog to Caffeine / Amphetamine.

## 2. Design principles & non-goals

- **Built openly** with public Apple frameworks (IOKit power assertions, CoreGraphics,
  SwiftUI, ServiceManagement, UserNotifications). No process obfuscation, no renaming to
  look like something else, no attempt to evade security tooling. If a managed-device
  policy blocks the app, the resolution is an IT exception — not evasion.
- **No third-party runtime dependencies.**
- **Single source of truth** for "is the Mac being kept awake, and why?"

## 3. Platform & distribution

| Aspect | Decision |
|---|---|
| Minimum OS | macOS 26 (latest) only |
| UI toolkit | SwiftUI (`MenuBarExtra`) + AppKit where needed |
| App type | Menu-bar agent — no Dock icon (`LSUIElement`) |
| Signing | Ad-hoc ("Sign to Run Locally") |
| Distribution | Personal / local use |

## 4. Functional requirements

### FR-1 — Keep-awake core
- While any rule is active, create IOKit power assertions preventing **both** display idle
  sleep (`kIOPMAssertionTypePreventUserIdleDisplaySleep`) and system idle sleep
  (`kIOPMAssertionTypePreventUserIdleSystemSleep`).
- Prevents screensaver and lock-on-idle (both are idle-triggered).
- Releases **all** assertions when no rule is active.

### FR-2 — Manual session modes (mutually exclusive)
- **Duration:** keep on for N hours; input via 0.5h stepper (min 0.5h).
- **Until time:** keep on until HH:MM; if the time already passed today, roll to the same
  time tomorrow.
- **Unlimited:** stay on until the user toggles off.
- Only one manual mode active at a time; starting one replaces any running manual session.

### FR-3 — Weekly schedule (OR'd with manual)
- Select weekdays (Mon–Sun) + **one shared** start–end time window applied to all selected days.
- Effective keep-awake = (manual session active) **OR** (now is within a scheduled window on a selected day).
- Schedule persists and is evaluated automatically whenever the app runs.

### FR-4 — Cursor jiggle (sub-feature, tied to session state)
- Global toggle; when ON, jiggle is active **exactly when** a keep-awake session (manual
  or scheduled) is active.
- **Idle-aware:** on a ~30s tick (configurable later), if the user has been idle
  (no input for ≥ ~25s), warp the cursor 1px and back. Skip while the user is actively
  using the mouse/keyboard so it never fights real input.
- Default implementation: `CGWarpMouseCursorPosition` (no permission required).
- Optional future mode: synthetic `CGEvent` mouse moves behind an explicit Accessibility
  opt-in, only if warp proves insufficient at resetting idle timers.

### FR-5 — Battery guard
- Configurable low-battery threshold (default 10%).
- On battery and level ≤ threshold → auto-stop the active session and notify.
- Auto-resume the interrupted session when power returns (AC connected, or level rises
  above threshold).
- Applies to both manual and scheduled sessions.

### FR-6 — Menu-bar UI
- Status-item icon reflects state: **idle vs active** (distinct glyph), and shows
  **remaining time** as small text for timed modes.
- Click → popover: current state/reason, mode picker (Duration / Until / Unlimited),
  start-stop toggle, schedule enable toggle, jiggle toggle, Settings link, Quit.
- Separate **Settings window:** schedule editor (days + window), battery threshold,
  jiggle interval, launch-at-login, notification preferences.

### FR-7 — Lifecycle
- Launch at login via `SMAppService`, **ON by default** (user can disable in Settings).
- On launch the schedule resumes automatically; manual timed sessions do **not** auto-resume.

### FR-8 — Notifications (opt-in)
- Notify on: session end, low-battery auto-stop, auto-resume. Request Notifications
  authorization on first relevant event.

## 5. Non-functional requirements

- **NFR-1** Zero third-party runtime dependencies.
- **NFR-2** Minimal CPU/memory; coalesced timers; no busy loops.
- **NFR-3** Single authoritative state model computing `effectiveAwake` + human-readable reason.
- **NFR-4** All settings persisted (`UserDefaults` / `@AppStorage`) and survive restart.
- **NFR-5** Graceful permission handling — never crash on a denied permission; degrade only the affected feature.
- **NFR-6** Core logic (schedule window calc, timers, battery guard) is UI-independent and unit-tested with Swift Testing.

## 6. Permissions matrix

| Capability | Permission required |
|---|---|
| Power assertions | None |
| Cursor warp jiggle (default) | None |
| Synthetic-event jiggle (future, optional) | Accessibility |
| Notifications | User authorization on first use |
| Launch at login | `SMAppService` (system toggle) |

## 7. Known limitations

- Cannot override MDM / managed-profile forced locks or "require password immediately"
  policies triggered by non-idle events.
- Critical/forced sleep (very low battery, lid close without external display, thermal)
  can still occur.
- Ad-hoc signing: the future synthetic-events mode may require re-granting Accessibility
  after each rebuild (the default warp jiggle is unaffected — it needs no permission).

## 8. Out of scope (v1)

- Per-day or multiple schedule windows.
- Clamshell / lid-closed keep-awake.
- iCloud sync of settings.
- Notarized public distribution.
