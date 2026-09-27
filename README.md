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

## Build & run

The Xcode project is added in Phase 0 (see [docs/PLAN.md](docs/PLAN.md)). Once present:

```bash
open Vigil.xcodeproj
```

Build & run in Xcode (⌘R). The app launches as a menu-bar agent — look for its icon
near the clock, not in the Dock.

## Project docs

- [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md) — full functional & non-functional spec.
- [docs/PLAN.md](docs/PLAN.md) — phased execution plan with acceptance criteria.

## Development: separate git identity

This repo is configured to use a **per-repo git identity** (not your global git user) and
to push via a dedicated **SSH host alias**, so it stays fully separated from your other
GitHub account. Setup steps live in [docs/PLAN.md](docs/PLAN.md#phase-0--project--repo-setup).

## Design note

Vigil uses only public Apple APIs (IOKit power assertions, CoreGraphics). It does **not**
disguise its process, rename itself, or attempt to bypass security software. On a
managed or corporate Mac, follow your organization's policies — if a keep-awake tool is
blocked, request an exception through IT rather than working around the control.
