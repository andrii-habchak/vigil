# Vigil — Execution Plan

Phased delivery. **Each phase produces a runnable build.** Acceptance criteria are the
gate to the next phase.

## Architecture (cross-cutting)

- **Pattern:** thin SwiftUI views over a testable core.
- **`AppState`** (`ObservableObject`) is the single source of truth:
  - `activeManualSession` (`.duration(end:)` | `.until(date:)` | `.unlimited` | `nil`)
  - `scheduleEnabled` + `ScheduleModel`
  - `jiggleEnabled`
  - `batteryPaused` (with the session to resume)
  - computes `effectiveAwake: Bool` and `reason: String` ("On until 18:00", "On (schedule)", "Paused — low battery").
- **Core modules (UI-independent, unit-tested):**
  - `PowerAssertionManager` — IOKit create/release.
  - `ScheduleEvaluator` — is `now` within a window on a selected day.
  - `SessionController` — duration/until math, ticking, expiry.
  - `BatteryGuard` — threshold transitions, pause/resume.
  - `JiggleController` — idle detection + warp.

---

## Phase 0 — Project & repo setup

- Create Xcode app project **Vigil** (SwiftUI lifecycle, macOS 26 target, `LSUIElement = true`, ad-hoc signing).
- Add `MenuBarExtra` scene with a placeholder icon + Quit.
- Add `.gitignore` (Xcode/Swift/macOS).
- `git init`; set **per-repo identity** and **SSH host-alias** remote (see below); initial commit.
- **Acceptance:** build & run shows a menu-bar status item with a working Quit; no Dock icon.

### Git & separate-identity setup

```bash
cd Vigil
git init
# Per-repo identity (does NOT touch your global config):
git config --local user.name  "<GITHUB_NAME>"
git config --local user.email "<GITHUB_EMAIL>"   # real or 12345+user@users.noreply.github.com

# Dedicated SSH key for this account (if you don't already have one):
ssh-keygen -t ed25519 -C "<GITHUB_EMAIL>" -f ~/.ssh/id_ed25519_<ALIAS>

# ~/.ssh/config host alias:
#   Host github-<ALIAS>
#     HostName github.com
#     User git
#     IdentityFile ~/.ssh/id_ed25519_<ALIAS>
#     IdentitiesOnly yes

# Add the PUBLIC key (~/.ssh/id_ed25519_<ALIAS>.pub) to the GitHub account, then:
git remote add origin git@github-<ALIAS>:<GITHUB_USER>/vigil.git
```

---

## Phase 1 — Keep-awake core + manual modes

- `PowerAssertionManager` (IOKit) create/release both display + system assertions.
- `SessionController` for Duration (0.5h stepper), Until (HH:MM, roll to tomorrow), Unlimited.
- Popover UI: mode picker + start/stop; icon reflects active/idle + remaining time.
- **Acceptance:** with a session active, `pmset -g assertions` lists
  `PreventUserIdleDisplaySleep` + `PreventUserIdleSystemSleep`; screen doesn't idle-sleep;
  the timer ends the session and releases assertions; icon updates live.

---

## Phase 2 — Weekly schedule

- `ScheduleModel` (selected days + shared window) + `ScheduleEvaluator`; minute-tick evaluation.
- Settings window with the schedule editor.
- OR logic with manual sessions; persistence.
- **Acceptance:** inside a configured window keep-awake activates automatically; outside it
  releases (unless a manual session holds); state survives relaunch.

---

## Phase 3 — Cursor jiggle

- `JiggleController`: idle detection via `CGEventSource.secondsSinceLastEventType`, ~30s tick,
  `CGWarpMouseCursorPosition` 1px and back; gated on session-active + toggle.
- Jiggle toggle in popover; interval in Settings.
- **Acceptance:** while idle in an active session the cursor micro-moves periodically;
  while actively using the mouse there's no interference; disabling the toggle stops it.

---

## Phase 4 — Battery guard, login item, notifications, tests, polish

- `BatteryGuard` via `IOPSCopyPowerSourcesInfo`; configurable threshold; auto-stop + auto-resume.
- `SMAppService` login item, default ON, Settings toggle.
- `UserNotifications` for session end / low-battery / resume.
- **Swift Testing** unit tests: schedule window calc (incl. tomorrow-roll and overnight
  windows), duration/until math, battery-guard transitions.
- Polish: icon state artwork, About, empty/error states.
- **Acceptance:** battery cutoff stops + notifies and resumes on AC; login item registers
  (visible in System Settings ▸ General ▸ Login Items); all tests pass.

---

## Open items to confirm before Phase 0

- Bundle identifier (reverse-DNS), e.g. `io.github.<user>.vigil`.
- GitHub username, commit email, SSH alias name (and whether a key already exists).
