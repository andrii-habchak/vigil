# Vigil

A native macOS menu-bar utility that keeps your Mac awake and can gently jiggle the
cursor. A minimal, modern analog to Caffeine / Amphetamine, built entirely with
Apple's public frameworks — **no third-party dependencies**.

## Features

- **Keep awake** — prevents display + system idle sleep, screensaver, and lock-on-idle.
- **Session modes** (one at a time):
  - **For N hours** — 0.5h stepper.
  - **Until a set time** — HH:MM; rolls to tomorrow if the time already passed today.
  - **Unlimited** — stays on until you switch it off.
- **Weekly schedule** — pick weekdays + one shared daily time window; runs automatically.
- **Cursor jiggle** — optional, idle-aware micro-movement, active only while a session is on.
- **Battery guard** — auto-stops at a configurable low-battery threshold and auto-resumes when power returns.
- **Menu-bar only** — no Dock icon; optional launch at login.

## Requirements

- macOS 26+
- Xcode (latest). An Apple ID for signing is optional — ad-hoc "Sign to Run Locally" is supported.

## Download & install

CI ([`.github/workflows/build.yml`](.github/workflows/build.yml)) builds a DMG on every
push and on version tags:

- **Latest build:** GitHub ▸ **Actions** ▸ latest *Build DMG* run ▸ **Artifacts** ▸
  `Vigil-dmg` (requires being signed in to GitHub).
- **Tagged release:** push a tag and the DMG is attached to a public GitHub Release:
  ```bash
  git tag v0.1.0 && git push origin v0.1.0
  ```
  Then grab `Vigil.dmg` from the repo's **Releases** page.

Open the DMG and drag **Vigil** to **Applications**. The build is **ad-hoc signed, not
notarized**, so on first launch macOS Gatekeeper will warn — **right-click Vigil.app →
Open** (once), or clear the quarantine flag:

```bash
xattr -dr com.apple.quarantine /Applications/Vigil.app
```

*(For a warning-free install you'd need an Apple Developer account and notarization —
see [Notes & limitations](#notes--limitations).)*

## Build & run

The Xcode project is generated from [`project.yml`](project.yml) with
[XcodeGen](https://github.com/yonwoo9/XcodeGen); the resulting `Vigil.xcodeproj` is
committed, so you can open it directly:

```bash
open Vigil.xcodeproj
```

Build & run in Xcode (⌘R). The app launches as a **menu-bar agent** — look for its icon
near the clock, not in the Dock. Quit it from its own menu (⌘Q).

### Terminal build / regenerate (optional)

Regenerate the project after structural changes:

```bash
xcodegen generate
```

Build from the terminal (this Mac's `xcode-select` points at the Command Line Tools, so
point at full Xcode for the build):

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme Vigil -destination 'platform=macOS' build
```

To make that permanent (needs your password):
`sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.

## Project docs

- [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md) — full functional & non-functional spec.
- [docs/PLAN.md](docs/PLAN.md) — phased execution plan with acceptance criteria.

## Development: separate git identity

This repo is configured to use a **per-repo git identity** (not your global git user) and
to push via a dedicated **SSH host alias**, so it stays fully separated from your other
GitHub account. Setup steps live in [docs/PLAN.md](docs/PLAN.md#phase-0--project--repo-setup).

## Notes & limitations

- **Launch at login** is ON by default and registers the running app bundle via
  `SMAppService`. For a dev build that's the transient DerivedData path — install Vigil to
  `/Applications` for a stable login item, or toggle it off in Settings.
- **Cursor jiggle** uses `CGWarpMouseCursorPosition` (no permission required). It moves the
  pointer but doesn't post an input event, so some apps' idle timers may not reset. A
  synthetic-event mode behind an Accessibility opt-in is a possible future addition.
- Vigil can't override MDM/managed-profile forced locks or critical/forced sleep (very low
  battery, lid close without external display, thermal).
- **Distribution:** CI produces an **ad-hoc-signed, non-notarized** DMG (no Apple Developer
  account required), which triggers a one-time Gatekeeper prompt. For a warning-free install,
  add an Apple Developer ID certificate + notarization to the workflow (needs a paid account
  and repo secrets for the cert, its password, and an app-specific/API-key credential).

## Design note

Vigil uses only public Apple APIs (IOKit power assertions, CoreGraphics). It does **not**
disguise its process, rename itself, or attempt to bypass security software. On a
managed or corporate Mac, follow your organization's policies — if a keep-awake tool is
blocked, request an exception through IT rather than working around the control.
