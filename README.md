# ATARI

**Empathetic Intelligence for User Productivity & On-Device Orchestration**

ATARI is a privacy-first Android productivity system that learns a user's normal
phone behaviour, detects unusual behavioural fragmentation, offers empathetic
interventions, and rewards intentional recovery through XP, levels, quests,
streaks, and achievements.

The repository is structured for a Flutter interface, native Android sensing,
local statistical analysis, and on-device language-model inference. Application
implementation has not started yet.

## Repository structure

```text
Atari/
├── .github/           GitHub collaboration templates
├── android/           Kotlin services and Android platform integration
├── assets/            Icons, animations, and local model assets
├── config/            Version-controlled configuration
├── docs/              Architecture and development documentation
├── integration_test/  End-to-end Flutter and device flows
├── lib/               Flutter application and behavioural engine
│   ├── core/          Shared models, services, storage, and design system
│   ├── engine/        Detection, orchestration, feedback, and progression
│   └── features/      User-facing product features
├── native/            llama.cpp runtime and native model bridge
├── research/          Research evidence and implementation decisions
├── scripts/           Development, build, benchmark, and release automation
├── test/              Unit and widget tests
├── .editorconfig      Shared editor defaults
├── .gitignore         Files intentionally excluded from Git
├── CONTRIBUTING.md    Contribution workflow
└── README.md          Project overview
```

## Architectural boundaries

- The statistical engine detects behavioural deviation.
- The local language model explains structured evidence; it does not perform
  detection or make medical or psychological diagnoses.
- Gamification rewards intentional action and recovery, not simply reduced
  screen time.
- Core behavioural data and inference remain on the device.

## Planned stack

- Flutter and Dart for the application interface
- Kotlin and Android SDK services for behavioural sensing
- SQLite with Drift for local storage
- Welford statistics and Z-scores for personal baselines
- llama.cpp with a quantised Gemma model for local explanations
- Android TextToSpeech for optional spoken interventions

See [CONTRIBUTING.md](CONTRIBUTING.md) for the working conventions.
