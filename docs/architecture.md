# Architecture

## Core loop

```text
Sense → Model → Detect → Explain → Intervene → Measure → Adapt
```

ATARI detects statistically unusual smartphone behavioural fragmentation
relative to a personal baseline. It does not infer or diagnose a user's mental
or medical state.

## Components

```text
Flutter UI
    ↓ platform channel
Kotlin Android sensing
    ↓ local events
Behaviour engine and personal baseline
    ↓ structured evidence
Intervention orchestrator + local Gemma explanation
    ↓
Focus experience + gamified progression
    ↓
Intervention-response measurement
```

### Flutter application

Owns presentation, navigation, goals, focus sessions, transparency controls,
insights, and gamification surfaces.

### Native Android layer

Owns usage access, notification timing metadata, device-state events, background
execution, and the platform bridge. It does not collect behavioral content that
is unnecessary for fragmentation detection.

### Behaviour engine

Owns Welford baseline statistics, bootstrap priors, Z-scores, fragmentation
scoring, intervention state transitions, cooldowns, and response measurement.
Detection remains deterministic and testable.

### On-device explanation

A quantised Gemma model receives structured evidence only after detection. It
generates a short, grounded explanation and does not decide whether the user is
fragmented.

### Gamification

The progression engine translates meaningful actions into XP, levels, quests,
streaks, and achievements. It rewards intentional recovery and completion rather
than indiscriminately rewarding low screen time.

### Local persistence

SQLite with Drift is planned for behavioral events, baseline buckets,
interventions, response observations, goals, progression, and settings.

## Privacy boundary

Core behavioural processing and inference remain local. Calendar or other
cloud-backed context is optional and must not become a dependency of the core
loop.

## Decisions

Record significant architectural decisions in short sections containing:

1. the problem or constraint
2. the options considered
3. the selected approach and its trade-offs
4. the date and status of the decision
