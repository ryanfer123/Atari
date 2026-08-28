# Flutter application

This directory will contain ATARI's Dart implementation.

```text
lib/
├── core/
│   ├── database/       Local persistence and migrations
│   ├── models/         Shared domain models
│   ├── services/       Shared application services
│   └── theme/          Design tokens and application theme
├── engine/
│   ├── baseline/       Personal baseline statistics
│   ├── detection/      Fragmentation scoring and thresholds
│   ├── feedback/       Intervention-response measurement
│   ├── gamification/   XP, levels, streaks, quests, and achievements
│   └── orchestration/  Intervention state machine and cooldowns
└── features/
    ├── dashboard/
    ├── focus/
    ├── gamification/
    ├── goals/
    ├── insights/
    ├── intervention/
    ├── onboarding/
    └── settings/
```

The engine owns deterministic decisions. UI features display state and collect
user intent; they must not independently determine whether fragmentation has
occurred.
