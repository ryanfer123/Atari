# Implementation Plan — ATARI (On-Device Overload Agent)
**iQOO City Battles 2026 · Open Innovation · 3-developer team (1 frontend, 2 backend), Claude Code as pair-programmer**

Companion to `RESEARCH.md` — read that first for *why* each component is built the way it is below.
This doc is the *how*: architecture, team/branch structure, permissions, and code skeletons.

---

## 0. Assumption to verify with organizers before Day 1

This plan assumes the 7 days are prep + practice, and the app that ships to judges is what gets
built live inside the 30-hour battle window (Sat 10:00 start / 11:00 active hacking → Sun awards),
per typical hackathon rules against pre-written submissions. **Confirm this with the iQOO City
Battles organizers on Day 1.** If pre-built code is allowed to carry into the battle, skip straight
to building the real app now and treat the whole 7 days as build time — the architecture below
doesn't change either way, only the calendar does.

The plan below assumes the conservative reading: **Days 1-5 = prototype + rehearse each component
in a scratch project; the 30-hour battle (Day 6-7) = assemble the real submission from what you've
already proven works.**

---

## 0.1 Scope expansion: goal-context layer

Beyond pure overload detection, the app now grounds its explanations in the user's notes, to-do
items, health targets, and (opt-in) calendar — see RESEARCH.md § "Expansion: goal-context layer" for
the full evidence chain. The short version, since it changes the architecture below:
- **Embeddings are used only for free-text notes** (EmbeddingGemma-300M). Todos, health targets, and
  calendar events are structured — query them directly, don't embed them.
- **No cross-source fusion.** Each data type is retrieved independently and combined only as flat
  context bullets in the final prompt — the literature (Setoka, Claw-Anything) shows even frontier
  models struggle at this when attempted as open-ended joint reasoning.
- **Calendar needs OAuth + network — everything else doesn't.** This is architected as a separate,
  explicitly opt-in module so the core loop's "zero `INTERNET` permission" claim stays literally true
  for the base app.

## 0.2 Team structure and git branching model

Three developers, split by **module ownership** rather than by feature — this is what actually keeps
merge conflicts rare, not communication discipline alone. A feature-based split ("you build capture,
you build gamification") guarantees every feature touches Flutter UI + engine logic + possibly native
code, so two devs edit the same files the same day. A layer-based split means each dev's changed-file
set almost never overlaps another dev's.

| Developer | Branch | Owns | Never touches |
|---|---|---|---|
| **Frontend** | `dev/frontend` | `lib/features/**`, `lib/core/theme/**`, `integration_test/**`, `assets/**` | `android/`, `native/`, `lib/engine/`, `lib/core/database/` |
| **Backend — Native** | `dev/backend-native` | `android/**`, `native/**`, `lib/core/services/**` (Dart-side platform-channel clients) | `lib/features/`, `lib/engine/`, `lib/core/database/` |
| **Backend — Engine** | `dev/backend-engine` | `lib/engine/**`, `lib/core/database/**`, `lib/core/models/**` (shared data contracts) | `lib/features/`, `android/`, `native/` |

**The one shared surface: `lib/core/models/`.** Data contracts (`OverloadEvent`, `ContextBullet`,
`CapturedItem`, `GamificationEvent`, etc. — shapes in §4) are used by all three branches and are the one
place conflicts can still happen. Three rules keep this safe:
1. Define every contract the MVP loop needs in a single **Sprint 0** session (all three devs together,
   see below) before branches diverge — this is the one deliberate exception where simultaneous editing
   is expected and fine.
2. After Sprint 0, changes to `lib/core/models/` are **additive-only** — new fields, new classes, never
   a rename or removal of something a merged branch already depends on. Any exception needs a PR all
   three devs review, not just the owning dev.
3. Frontend never blocks on the real engine or native layer to build UI. Sprint 0 also produces
   `lib/core/services/fakes/` — hand-written fake implementations of every contract-based interface,
   returning realistic canned data. Frontend builds and demos against fakes the whole time; swapping a
   fake for the real implementation at integration time is a one-line dependency-injection change, not a
   rewrite.

**Git mechanics ("secure timeline, no merge conflicts"):**
- `main` is protected: no direct pushes, PR required, required CI check (format + lint + `flutter test`),
  **squash-merge only** — this keeps `main`'s history linear and bisectable, which is what "secure
  timeline" means here: auditable and revertible, not just access-controlled.
- Each dev works day-to-day in their own long-lived `dev/*` branch, cutting short-lived `feat/*` branches
  from it for individual PRs into `main`, using the prefixes already in `CONTRIBUTING.md`.
- **Rebase onto `main` daily** — `git pull --rebase origin main` — don't merge `main` into a feature
  branch. Rebasing is what keeps three parallel branches from accumulating tangled merge-commit history;
  with the ownership split above, a rebase should almost always be conflict-free because the changed
  files genuinely don't overlap.
- Add `.github/CODEOWNERS` mapping the paths above to each developer — GitHub then requires that dev's
  review before a PR touching their paths can merge, automating the ownership split instead of relying
  on it being remembered.
- **If a conflict does happen, treat it as a signal the ownership boundary was crossed** (most likely:
  someone edited `lib/core/models/` outside Sprint 0 or an agreed contract-change PR), not just a normal
  conflict to resolve and move past — re-confirm ownership before continuing.

**Sprint 0 (half a day, all three devs together, before branches diverge):**
1. Agree and write the `lib/core/models/` contracts for the MVP loop (`OverloadEvent`, goal-context
   `ContextBullet`, `CapturedItem`, `GamificationEvent` — shapes in §4).
2. Write `lib/core/services/fakes/` so frontend can build against realistic fake data immediately.
3. Create the three `dev/*` branches from `main`; confirm `CODEOWNERS` and branch protection are live.
4. Agree integration checkpoints (end of each day/sprint) where all three branches rebase and a real
   end-to-end smoke test runs — integration happens continuously, not only once at the end.

## 0.3 Scope expansion: gamified capture-to-organize layer

Beyond overload detection and goal-context grounding, the app now includes (a) a freeform, Google-Lens-
style capture flow — draw a loose shape over a photographed page or on-screen content, get a clean crop
and structured items extracted from it — and (b) a gamification layer (XP, levels, quests, streaks,
achievements) rewarding completion and intentional recovery, per the existing README boundary. See
RESEARCH.md § "Expansion: gamified capture-to-organize layer" for the full evidence chain. The short
version, since it changes the architecture below:
- **Capture is a compose-two-models pipeline, not one.** A segmentation model (EdgeSAM-class) turns the
  loose scribble into a clean mask/crop; a dewarping model (DocScanner-class) flattens it only if it's a
  photographed page at an angle — a pure in-app screenshot region skips this step, it's already flat. No
  single paper does both, so this is genuinely first-party integration work.
- **OCR output feeds the existing note pipeline — it does not get its own embedding, yet.** Extracted
  text runs through EmbeddingGemma-300M exactly like a typed note (§0.1). A dedicated image embedder
  (MobileCLIP2) is a measured upgrade, not a default — the literature is genuinely split on whether it's
  needed for this content type (RESEARCH.md § same section).
- **Gamification rewards completion and effort, never raw suppression, and never uses a losable streak.**
  Direct response to literature showing streak/reward mechanics can independently increase anxiety and
  compulsive checking (RESEARCH.md § same section) — this is also already the project's own README
  boundary, now with the evidence behind it made explicit, and a self-audit checklist (§4.7) to check it
  was actually followed.

## 0.4 Scope expansion: flagship-hardware agentic upgrade

The confirmed demo/dev hardware is an **iQOO flagship phone — 16GB RAM, Snapdragon-class NPU, 512GB
storage** — not the generic loaner device the original 1B-model budget was conservatively sized for.
See RESEARCH.md § "Expansion: flagship-hardware agentic upgrade" for the full evidence chain. The short
version, since it changes the architecture and stack below:
- **On-device SLM upgrades from Gemma 3 1B to Qwen3-4B** (primary), with Qwen3-8B as a measured upgrade
  path only if Day-1 device testing on the actual iQOO flagship confirms headroom, and Gemma 3 4B as
  the GGUF-integration-path alternate. This is a real change to §2/§4, not just an addition.
- **The Tier 1 rule-based classifier and the no-cross-source-fusion rule both stay exactly as they
  were.** Neither was a hardware-limited decision (RESEARCH.md § same section explains why) — better
  hardware doesn't change either conclusion.
- **"Autonomous orchestration" is scoped narrowly and deliberately: masked, code-governed tool
  selection at specific decision points, never a free-form multi-step agent loop.** The evidence against
  open-ended multi-step tool orchestration is unusually consistent across model sizes, including
  frontier cloud models (RESEARCH.md § same section) — the concrete change is that `GoalContext`
  retrieval (§4.5) becomes a model-selected subset of sources instead of always querying all of them,
  bounded by a masked candidate set, schema validation, and a hard call cap. Everything else in the
  core state machine (`Orchestrator`, `FeedbackLoop`, `GamificationEngine`) stays deterministic,
  code-governed control flow.

## 1. Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Signal Collectors (Android system APIs, metadata only)         │
│  ├─ UnlockTracker        (BroadcastReceiver: ACTION_USER_PRESENT)│
│  ├─ AppSwitchTracker     (UsageStatsManager.queryEvents)         │
│  └─ NotifLatencyTracker  (NotificationListenerService)           │
└───────────────┬───────────────────────────────────────────────────┘
                │  raw events, every ~1 min (WorkManager periodic)
                ▼
┌─────────────────────────────────────────────────────────────────┐
│  BaselineStore (Room/SQLite, on-device only)                    │
│  Per-signal Welford online mean/var, bucketed by                │
│  (hour_of_day, day_of_week). Bayesian population-prior blend     │
│  for cold start: Ĝ_t = w(t)·prior + (1−w(t))·empirical           │
└───────────────┬───────────────────────────────────────────────────┘
                │  z-scores per signal
                ▼
┌─────────────────────────────────────────────────────────────────┐
│  OverloadClassifier (Tier 1, rule-based)                         │
│  weighted z-score sum > threshold → OVERLOAD state               │
└───────────────┬───────────────────────────────────────────────────┘
                │  OverloadEvent(signals, zscores, severity)
                ▼
┌─────────────────────────────────────────────────────────────────┐
│  Orchestrator (state machine + cooldown + consent gate)          │
│  NORMAL → OVERLOAD_DETECTED → INTERVENING → COOLDOWN → NORMAL    │
│  picks intervention type via epsilon-greedy bandit                │
└──────┬──────────────────────────────────┬─────────────────────────┘
       │ structured JSON snapshot         │ trigger
       ▼                                  ▼
┌───────────────────┐          ┌──────────────────────────────┐
│ SlmExplainer         │          │ FocusOverlay (full-screen     │
│ Qwen3-4B GGUF (§0.4)  │          │ intent activity)               │
│ via llama.cpp JNI      │───────▶│ muted UI, 3 essential apps,   │
│ → masked source pick   │  text   │ explanation text + TTS voice  │
│ + one-sentence explain │         │                                 │
└─────────┬─────────┘          └───────────────┬──────────────────┘
          ▲
          │ flat bullets from only the sources the model picked
          │ (masked choice among ≤5 sources — still no fusion, §0.1/§0.4)
┌─────────┴─────────────────────────────────────────────────────┐
│  GoalContext (retrieval-per-source, model-selected subset,       │
│  combined only at prompt time — masking + schema validation +    │
│  call cap per §4.5/§4.8, never a free multi-step agent loop)     │
│  ├─ Notes: EmbeddingGemma-300M, on-device cosine top-k            │
│  ├─ Todos / HealthTargets: Room, direct field filter (no embed)  │
│  └─ Calendar (opt-in, OAuth): time-range filter (no embed)        │
└──────────────────────────────┬────────────────────────────────────┘
                                │ CapturedItem (parsed, user-confirmed)
                                │
┌───────────────────────────────┴───────────────────────────────────┐
│  Capture pipeline (native vision models, on-device)                │
│  freeform scribble → EdgeSAM-class mask/crop                       │
│  → DocScanner-class dewarp (photo only, skipped for screenshots)   │
│  → PP-OCRv5/6 OCR → user reviews/edits → saved as Note/Todo/       │
│    HealthTarget, feeds GoalContext above like any other entry      │
└─────────────────────────────────────────────────────────────────────┘
                                                 │ user dismisses / cooldown ends
                                                 ▼
                                ┌──────────────────────────────┐
                                │ FeedbackLoop                    │
                                │ re-measure signals post-window, │
                                │ log pre/post effect size,        │
                                │ update bandit + thresholds       │
                                └──────────────┬───────────────────┘
                                                │ intervention worked / todo done /
                                                │ capture-to-organize completed
                                                ▼
                                ┌──────────────────────────────────┐
                                │ GamificationEngine                  │
                                │ XP + levels + quests + non-losable  │
                                │ streaks + achievements — rewards    │
                                │ completion/effort, never raw        │
                                │ reduced screen time (RESEARCH.md)   │
                                └──────────────────────────────────┘
```

No component in the core loop (everything above except the optional Calendar source) makes a network
call — the Capture pipeline's segmentation, dewarping, and OCR models all run on-device, same as the SLM
and embedder. The base app's `AndroidManifest.xml` declares **no `INTERNET` permission at all** —
checkable by a judge in Settings → App Info in about 10 seconds. Calendar sync is a separate opt-in
module with its own permission grant, not bundled into the base install — see §5.1.

---

## 2. Stack decisions

Full evidence chain (numbers + logic, including what's *not* backed by a citation and why) is in
RESEARCH.md § "Decision justification" — this table is the summary.

| Component | Choice | Why |
|---|---|---|
| Signal collection | `UsageStatsManager`, `NotificationListenerService`, `ACTION_USER_PRESENT` broadcast | All native Android, metadata-only, no special hardware |
| Baseline storage | Room (SQLite) | Local-only, no sync, trivial to demo-reset between runs |
| Classifier | Rule-based Welford z-score, hand-tuned thresholds | O(log n) vs O(n) sample-complexity theory (arXiv:2302.02334) + a direct empirical analog hitting precision=1.00/recall=1.00 at 14-day data scale (arXiv:2604.08581) both favor rule-based at this project's data volume — not just a time-budget shortcut |
| On-device SLM | **Qwen3-4B, Q4 GGUF** (primary); **Qwen3-8B** upgrade path if Day-1 flagship testing confirms headroom; **Gemma 3 4B** GGUF-path alternate | Sits in the size band real-device measurement confirms actually runs on mobile today (arXiv:2504.00002); real evidence of agentic/tool-use capability at 4B (MidTool, ToolRM); 8B has the strongest accuracy number (UniToolCall 93.0% precision) but unverified peak RAM alongside embedder+vision — see RESEARCH.md §Expansion: flagship-hardware agentic upgrade. Supersedes the original Gemma 3 1B pick, which was sized for a generic loaner device, not this confirmed flagship |
| SLM harness | Fork **PhoneLM's Android demo app** (github.com/UbiquitousLearning/PhoneLM) for the JNI/GGUF-loading plumbing, swap in the Qwen3-4B weights | Only source found with a *working* Android llama.cpp harness — don't build this from scratch. Harness itself doesn't change with the model swap, only the loaded weights and prompt/tool-schema handling |
| Agentic tool selection | Masked, code-governed selection at defined decision points (chiefly GoalContext source retrieval, §4.5/§4.8) — **not** a free-form multi-step agent loop | Every positive small-model tool-calling result found requires a masked/retrieval-narrowed candidate set (Octopus, Hammer, DroidCall, TinyAgent); every raw multi-step orchestration number found is weak even for frontier cloud models (HyperTool, Evoflux, TOBench) — see RESEARCH.md §Expansion: flagship-hardware agentic upgrade |
| Voice output | Android `TextToSpeech` (offline engine) | Zero extra permission, covers HackTracker's "voice" line without touching the mic |
| Overlay UI | `USE_FULL_SCREEN_INTENT` activity (MVP) → `SYSTEM_ALERT_WINDOW` overlay (stretch) | Full-screen intent is far lower permission-risk for a live demo; upgrade only if time remains |
| Dev bridge | Office Kit, paired for the whole build | Screen mirror for on-device debugging, file transfer for pulling logs off the loaner phone — scored on real usage, use it don't fake it |
| Note embeddings | **EmbeddingGemma-300M**, GGUF or q4 ONNX | SOTA <500M on MTEB, verified running on-device on Android in a real RAG system (MAM-AI) — see RESEARCH.md §Expansion. Fallback: Snowflake Arctic-Embed-XS (22.5M) if RAM is tight |
| Todos / health targets | Room, direct structured queries — **no embeddings** | They're structured records (deadline, metric, threshold) — a field filter is cheaper and more reliable than semantic search over the same content |
| Cross-source combination | Flat context bullets concatenated at prompt time — **no joint fusion/reasoning** | Literature (Setoka, Claw-Anything) shows even frontier models struggle at open-ended multi-source fusion (34.5% pass@1) — don't attempt it at hackathon scale |
| Calendar | Google Calendar API via OAuth, **opt-in module, separate permission** | Only component needing network/auth — architected as additive so the core loop's zero-`INTERNET` claim stays literally true |
| Freeform capture: scribble → crop | **EdgeSAM** (CNN-distilled SAM, edge-targeted, code released) | Most concretely edge-deployable interactive-segmentation model found with released weights — RESEARCH.md §Expansion (gamified capture) |
| Freeform capture: dewarp | **DocScanner** (progressive/iterative rectification, code released) | Lightweight, iterative-refinement design fits compute budget; only invoked for camera-photo captures, skipped for in-app screenshots |
| Captured-image OCR | **PP-OCRv5/PP-OCRv6** (classical OCR, 1.5-35M params) for MVP; **PaddleOCR-VL** (0.9B) as upgrade if table/timetable structure is lost | Tiny/deployable-first; upgrade path exists but isn't the default — don't reach for the VLM before measuring whether classical OCR is enough |
| Captured-image embedding | **None by default** — OCR text goes through the existing EmbeddingGemma-300M note pipeline; **MobileCLIP2** only if that's measurably insufficient | Literature is genuinely split (DSE/UniSE favor dedicated image embedding, CIVIL favors caption+text-embedding) — ship the cheaper path first, upgrade only on measured need |
| Gamification design principle | Reward completion/effort (todo done, capture parsed, intervention confirmed working); **non-losable** streaks/levels, never raw reduced-screen-time | Streak/reward mechanics independently increase anxiety and compulsive checking in the literature (arXiv:2411.09706) — this rule is the mitigation, not optional polish |

**Path not taken:** MediaPipe/Google AI Edge's LLM Inference API was considered as a higher-level
alternative to raw llama.cpp JNI, but this survey did not verify its GGUF compatibility or confirm
a working example against Gemma-family or Qwen3 models specifically (coverage gap — MLC-LLM/ExecuTorch
returned no arXiv/HF-Papers hits at all). Treat it as a half-day spike early in the backend-native
workstream, not the default: if the PhoneLM-fork + llama.cpp path is compiling and loading Qwen3-4B
within Sprint 0's first days, stop evaluating alternatives and commit.

---

## 3. Team plan: Sprint 0, then three parallel workstreams

The old solo "Day 1-7" sequence doesn't fit a 3-person team well — most of it can run in parallel once
the contracts in Sprint 0 (§0.2) exist. What follows keeps every exit criterion from the original plan
but attributes each piece of work to the branch/dev that owns it, and adds explicit integration
checkpoints so the three branches don't just diverge for a week and collide at the end.

### Sprint 0 (half day, all three devs together — see §0.2 for the mechanics)
- Confirm pre-build rules with organizers (§0).
- Set up Android Studio + Flutter toolchain for all three devs; pair Office Kit to the loaner/dev
  phone, confirm screen mirror + file transfer work (this is graded usage — start the clock on it now,
  not on Day 6).
- Write the Sprint-0 contracts in `lib/core/models/`: `OverloadEvent`, `ContextBullet`, `CapturedItem`,
  `GamificationEvent` (shapes in §4), plus the `lib/core/services/fakes/` package returning realistic
  canned data for each.
- Create `dev/frontend`, `dev/backend-native`, `dev/backend-engine` from `main`; confirm `CODEOWNERS`
  and branch protection are live.
- Exit criterion: all three branches exist, contracts compile, frontend can already run the app shell
  against fakes.

### Workstream: Frontend (`dev/frontend`)
Builds and demos entirely against `lib/core/services/fakes/` until integration — never blocked on the
other two branches being real.
- One-time consent screen on first launch (list exactly which signals are collected and why — this
  doubles as demo material for the privacy pitch).
- Dashboard: the always-available "transparency panel" (raw signal counts + z-scores + last few
  interventions + measured effect) — see §6.
- `FocusOverlay` UI: full-screen intent, muted color scheme, 3 pinned "essential" apps
  (user-configurable in settings), explanation text slot fed by `SlmExplainer` output.
- Todo / health-target CRUD screens (Room-backed forms — deadline field on todos, metric+threshold on
  health targets — cheap UI work, no ML involved, see §0.1).
- **Capture flow UI:** camera capture screen → freeform scribble/circle gesture canvas over the
  captured frame → crop preview → OCR-result review/edit screen (the extraction will be wrong
  sometimes; editability before saving is not optional) → save as Note/Todo/HealthTarget.
- **Gamification UI:** XP/level bar, quest list, non-losable streak display, achievements — built
  against `GamificationEvent` fakes from Sprint 0.
- Calendar "Connect calendar (optional)" opt-in screen (stretch, §7).
- Integration-test coverage (`integration_test/`) for the flows above running against fakes.
- Exit criterion: every screen above is demoable end-to-end against fake data before any real
  backend branch has merged.

### Workstream: Backend — Native (`dev/backend-native`)
Owns everything that talks to the OS or runs an on-device model via native inference.
- `UnlockTracker`: `BroadcastReceiver` on `ACTION_USER_PRESENT`, persisted via a `WorkManager`
  periodic worker (Android kills raw long-lived receivers).
- `AppSwitchTracker`: `UsageStatsManager.queryEvents()`, count `MOVE_TO_FOREGROUND` transitions in
  rolling windows.
- `NotifLatencyTracker`: `NotificationListenerService`, log `onNotificationPosted` timestamp vs. the
  next unlock or `onNotificationRemoved` — **metadata only, never read notification text/content.**
- SLM harness: fork PhoneLM's Android demo (github.com/UbiquitousLearning/PhoneLM), get it compiling
  and running its own default model on-device, then swap in a **Qwen3-4B Q4 GGUF** and measure
  cold-load time + tokens/sec on the actual **iQOO flagship's** Snapdragon NPU. **This number does not
  exist in any paper for a phone-class Snapdragon NPU at this size — this is the first data point**
  (RESEARCH.md §Expansion: flagship-hardware agentic upgrade). If headroom is genuinely better than
  expected, try Qwen3-8B as the measured upgrade; if the Qwen3 GGUF/tool-calling path is harder to
  integrate than expected, fall back to Gemma 3 4B to stay in-family with the existing harness.
  **Spend real time on the few-shot prompt and tool-call schema (§4.3/§4.8), not just model loading** —
  Time2Stop (arXiv:2403.05584) measured +53.8%/+11.4% receptivity gain from adding explanations, so the
  explanation's quality is plausibly the highest-leverage thing in the whole build.
- **Capture pipeline native bridge:** EdgeSAM (scribble → mask/crop), DocScanner (dewarp,
  photo-captures only), PP-OCRv5/6 (OCR) — same class of work as the SLM harness (load a small
  on-device model, expose it over a JNI/platform-channel boundary), so it sits with the same owner.
  Measure latency for each stage on the flagship device — none of these have published Android numbers
  (RESEARCH.md §Expansion, gamified capture).
- **Concurrent-model memory/latency testing:** once the SLM, embedder, and capture pipeline each work in
  isolation, test them **resident together** — peak RSS and latency under concurrent load, not just each
  model's own footprint. No paper validates this combination on phone hardware (RESEARCH.md §Expansion:
  flagship-hardware agentic upgrade) — the ~4-6GB combined estimate against 16GB available is a
  hypothesis to verify, not an assumption to build on unverified.
- Wire `TextToSpeech` (offline engine) to speak explanations.
- Permission plumbing: usage access, notification access, full-screen intent, camera — manual-grant
  flows per §5.
- Expose every capability above through the `lib/core/services` platform-channel contract Sprint 0
  defined, so frontend and backend-engine can each swap their fakes for the real implementation
  independently.
- Exit criterion: each native capability (signal collectors, SLM, capture pipeline) is independently
  testable via a minimal debug harness/test screen, callable through the agreed contract.

### Workstream: Backend — Engine (`dev/backend-engine`)
Owns deterministic logic and local storage — testable without any UI or native code.
- `BaselineStore`: Welford online mean/variance per (hour_of_day, day_of_week) bucket per signal, plus
  the Bayesian cold-start blend (RESEARCH.md, Dotsin concept #3) with hardcoded population-default
  priors (there's no published number for these — pick defaults from dogfooding, document them inline
  as the project's own empirical contribution). Code skeleton in §4.1.
- `OverloadClassifier` + `Orchestrator` state machine (`NORMAL → OVERLOAD_DETECTED → INTERVENING →
  COOLDOWN`), cooldown timer. Code skeleton in §4.2.
- `FeedbackLoop` + epsilon-greedy bandit: on cooldown end, re-pull the same signal window, compute
  pre/post effect size, log it, update weights over intervention variants (start with 2: "focus layer"
  vs. "single suggested-break notification"; add the "light friction" arm from §7 if time allows).
  Flag "worked" at **≥5% signal reduction** (RESEARCH.md "Decision justification" — real JITAI effect
  sizes cluster at 7-17%). A null result for one arm is valid bandit signal, not a bug — see
  RESEARCH.md's Protégé-effect null-result caution. Code skeleton in §4.4.
- `GoalContext` retrieval: notes via EmbeddingGemma-300M cosine top-k, todos/health-targets/calendar
  via direct Room query, combined only as flat prompt bullets — never joint fusion (RESEARCH.md
  §Expansion: goal-context layer). **Which sources get queried is now the model's masked choice**
  (≤5 known sources, schema-validated, hard call cap), not a fixed always-query-all list — the
  agentic upgrade, scoped exactly per RESEARCH.md §Expansion: flagship-hardware agentic upgrade.
  Code skeletons in §4.5 (retrieval) and §4.8 (masked tool selection).
- **`CapturedItem` parsing:** maps backend-native's OCR output into a structured Note/Todo/
  HealthTarget candidate, handles dedup/merge against existing entries, persists to Room, and feeds
  `GoalContext` like any other entry. Code skeleton in §4.6.
- **`GamificationEngine`:** XP/level/quest/non-losable-streak state machine, triggered by
  `FeedbackLoop` success, todo/health-target completion, and capture-to-organize completion — never by
  raw reduced screen time (RESEARCH.md §Expansion: gamified capture-to-organize layer). Code skeleton
  in §4.7, including the pre-ship self-audit checklist.
- Exit criterion: the full engine is testable end-to-end with synthetic/fake native inputs (from
  Sprint 0's fakes or backend-native's debug harness) — no UI needed to verify correctness.

### Integration checkpoints
- **Daily:** all three branches rebase onto `main`; whoever has a mergeable increment opens a PR
  (reviewed per `CODEOWNERS`).
- **As branches stabilize:** swap fakes for real implementations one at a time (e.g. frontend's
  `SlmExplainer` fake → backend-native's real one) rather than all at once at the end — this is what
  actually catches contract mismatches while there's still time to fix them.
- **Final exit criterion (replaces the old solo Day 5 criterion):** hand the phone to someone not on
  the team; they toggle airplane mode on, force an overload state, photograph a schedule and circle an
  item to capture it, and watch the full loop — detection, explanation, overlay, capture-to-organize,
  XP award — complete without any of the three devs touching the device.

### Day 6-7 — The 30-hour battle (whole team)
- **Green Light (both devices):** heavier work first — any stretch goal from §7, threshold re-tuning
  against real battle-day usage, UI polish, capture-pipeline accuracy passes. Use laptop compute for
  anything Gradle/build-heavy.
- **Red Light (phone-only via Office Kit):** the app itself must already be feature-complete and
  running fully on-device by the time Red Light windows hit — Red Light changes *how the team drives
  the laptop* (remote control via Office Kit), not what the app needs to do. Use these windows for
  on-device debugging, log pulling, and demo rehearsal.
- Final hours: freeze features, rehearse the pitch (§6) as a team (decide who narrates which beat),
  confirm permissions are pre-granted on the actual demo device, confirm `INTERNET` permission is
  absent from the base manifest as a last check, and run the gamification dark-patterns self-audit
  (§4.7) if it hasn't happened yet.

---

## 4. Core code skeletons

### 4.1 Welford online baseline (`BaselineStore.kt`)

```kotlin
data class SignalBucket(
    val signal: String,          // "unlocks" | "app_switches" | "notif_latency_ms"
    val hourOfDay: Int,          // 0-23
    val dayOfWeek: Int,          // 1-7
    var count: Long = 0,
    var mean: Double = 0.0,
    var m2: Double = 0.0         // sum of squared deviations, for variance
) {
    fun update(x: Double) {
        count++
        val delta = x - mean
        mean += delta / count
        val delta2 = x - mean
        m2 += delta * delta2
    }

    fun variance(): Double = if (count < 2) Double.NaN else m2 / (count - 1)

    /** Bayesian cold-start blend: population prior decays out as personal data accumulates. */
    fun blendedMean(populationPrior: Double, halfLifeObservations: Int = 20): Double {
        val w = Math.pow(0.5, count.toDouble() / halfLifeObservations)
        return w * populationPrior + (1 - w) * mean
    }

    fun zScore(x: Double, populationPrior: Double, populationStd: Double): Double {
        val effectiveMean = blendedMean(populationPrior)
        val std = if (count < 5) populationStd else Math.sqrt(variance()).coerceAtLeast(1e-6)
        return (x - effectiveMean) / std
    }
}
```

Persist `SignalBucket` rows in Room, keyed on `(signal, hourOfDay, dayOfWeek)`, upserting on each
new observation. `populationPrior`/`populationStd` per signal are hardcoded defaults from your own
dogfooding — document them inline, they're the project's own empirical contribution since nothing in
the literature provides them (see RESEARCH.md coverage gaps).

### 4.2 Classifier + orchestrator sketch

```kotlin
data class OverloadEvent(
    val timestamp: Long,
    val signalScores: Map<String, Double>,   // signal -> z-score
    val severity: Double                     // weighted sum
)

class OverloadClassifier(private val weights: Map<String, Double>, private val threshold: Double) {
    fun classify(zScores: Map<String, Double>): OverloadEvent? {
        val severity = zScores.entries.sumOf { (signal, z) -> (weights[signal] ?: 0.0) * z.coerceAtLeast(0.0) }
        return if (severity > threshold) OverloadEvent(System.currentTimeMillis(), zScores, severity) else null
    }
}

enum class AgentState { NORMAL, OVERLOAD_DETECTED, INTERVENING, COOLDOWN }

class Orchestrator(private val cooldownMs: Long = 15 * 60_000) {
    var state = AgentState.NORMAL
        private set
    private var lastInterventionAt = 0L

    fun onOverloadEvent(event: OverloadEvent): Boolean {
        val now = System.currentTimeMillis()
        if (state != AgentState.NORMAL) return false
        if (now - lastInterventionAt < cooldownMs) { state = AgentState.COOLDOWN; return false }
        state = AgentState.OVERLOAD_DETECTED
        lastInterventionAt = now
        return true // caller triggers SlmExplainer + FocusOverlay
    }

    fun onInterventionShown() { state = AgentState.INTERVENING }
    fun onCooldownElapsed() { state = AgentState.NORMAL }
}
```

### 4.3 SLM prompt shape

Keep the prompt to a fixed template so a 1B model stays reliable — don't ask it to reason freely:

```
System: You explain phone-overload signals in exactly one short, plain sentence. No lists, no advice.
User: signals={"unlocks_z":2.4,"switches_z":3.1,"notif_latency_z":-0.3}, top_signal="app_switches",
      baseline_context="Tuesday afternoon"
Assistant: Your app-switching is much higher than your usual Tuesday-afternoon pattern.
```

Few-shot 3-4 fixed examples in the system prompt covering each `top_signal` case beats zero-shot
reliability at 1B scale — budget real spike time for this early in the backend-native workstream, not
just the model-loading spike.

### 4.4 Feedback loop / bandit sketch

Epsilon-greedy, not UCB/Thompson sampling — chosen because expected trial count over the build/demo
window is only ~5-25 (HeartSteps real-world JITAI cadence, RESEARCH.md "Decision justification"), too
few for a confidence-bound or posterior-sampling algorithm to earn its added complexity.

```kotlin
/** ≥5% reduction counts as "worked" — real JITAI effect sizes cluster at 7-17%, not dramatic swings.
 *  See RESEARCH.md "Decision justification" (Time2Stop, InteractOut, MindShift). */
const val INTERVENTION_SUCCESS_THRESHOLD = 0.05

class InterventionBandit(private val arms: List<String>, private val epsilon: Double = 0.2) {
    private val effectSums = mutableMapOf<String, Double>().withDefault { 0.0 }
    private val pulls = mutableMapOf<String, Int>().withDefault { 0 }

    fun choose(): String {
        if (Math.random() < epsilon || arms.any { pulls.getValue(it) == 0 }) return arms.random()
        return arms.maxByOrNull { effectSums.getValue(it) / pulls.getValue(it).coerceAtLeast(1) }!!
    }

    /** effectSize: fractional signal drop after intervention, e.g. 0.08 = 8% reduction (good).
     *  A negative or near-zero effectSize is a legitimate outcome, not an error — log it and let
     *  the running average naturally down-weight that arm; don't special-case "no effect" as a bug. */
    fun record(arm: String, effectSize: Double) {
        effectSums[arm] = effectSums.getValue(arm) + effectSize
        pulls[arm] = pulls.getValue(arm) + 1
    }
}
```

### 4.5 Goal-context retrieval — per-source, no fusion

Each source is queried independently; combination happens only as string concatenation right before
the prompt is built, never as a joint embedding space (see §0.1 and RESEARCH.md §Expansion).

```kotlin
data class ContextBullet(val source: String, val text: String)

class GoalContext(
    private val notesEmbedder: EmbeddingGemma,          // cosine top-k over on-device note vectors
    private val todoStore: TodoDao,                     // Room, direct query
    private val healthTargetStore: HealthTargetDao,      // Room, direct query
    private val calendarStore: CalendarDao?               // null if user hasn't opted in — see §5.1
) {
    fun retrieve(triggerSignal: String, now: Long): List<ContextBullet> {
        val bullets = mutableListOf<ContextBullet>()
        notesEmbedder.topK(query = triggerSignal, k = 2)
            .forEach { bullets += ContextBullet("note", it.text) }
        todoStore.dueWithin(now, windowMs = 2 * 60 * 60_000)
            .forEach { bullets += ContextBullet("todo", "${it.title} (due ${it.deadline})") }
        healthTargetStore.activeTargets()
            .forEach { bullets += ContextBullet("health", "${it.metric} target: ${it.threshold}") }
        calendarStore?.eventsWithin(now, windowMs = 60 * 60_000)
            ?.forEach { bullets += ContextBullet("calendar", "${it.title} at ${it.startTime}") }
        return bullets  // flat list — SlmExplainer's prompt template appends these as plain bullets
    }
}
```

`calendarStore` being nullable *is* the opt-in architecture — the whole class works with zero,
one, or all sources present, and the core overload-detection loop never depends on this class at all
(it's an enrichment SlmExplainer's prompt optionally uses, not a dependency of the classifier/
orchestrator).

### 4.6 Capture pipeline — freeform crop → OCR → structured item

Owned end-to-end by backend-native (the model stages) and backend-engine (the parsing/persistence
stage) across the platform-channel contract from Sprint 0. Frontend only sees `CaptureResult`.

```kotlin
// backend-native: native/vision bridge, same pattern as the llama.cpp SLM harness
data class CaptureResult(
    val rectifiedImagePath: String,   // after EdgeSAM crop + DocScanner dewarp (dewarp skipped for screenshots)
    val ocrText: String,              // raw PP-OCRv5/6 output, unstructured
    val ocrConfidence: Float
)

interface CapturePipeline {
    /** origin distinguishes "camera photo" (needs dewarp) from "in-app screenshot" (already flat). */
    suspend fun capture(scribblePoints: List<Offset>, sourceImage: Bitmap, origin: CaptureOrigin): CaptureResult
}
```

```kotlin
// backend-engine: lib/engine/capture — turns raw OCR text into a candidate structured item
data class CapturedItem(
    val rawText: String,
    val suggestedType: ItemType,      // NOTE | TODO | HEALTH_TARGET — heuristic guess, user confirms in UI
    val suggestedTitle: String,
    val suggestedDeadline: Long?,     // parsed if a date/time pattern is found, else null
    val confidence: Float
)

class CapturedItemParser {
    /** Deliberately simple heuristics, not a second LLM call — see RESEARCH.md §Expansion
     *  (gamified capture): OCR text already goes through the existing GoalContext note pipeline,
     *  a dedicated parsing model is out of scope for MVP. */
    fun parse(ocrText: String): CapturedItem {
        val deadline = extractDateTimePattern(ocrText)  // simple regex/date-pattern matching
        val type = if (deadline != null) ItemType.TODO else ItemType.NOTE
        return CapturedItem(ocrText, type, ocrText.lineSequence().first(), deadline, confidence = 0.6f)
    }
}
```

The UI (frontend) always shows `CapturedItem` in an editable review screen before saving — OCR and the
type/deadline heuristic will both be wrong sometimes, and RESEARCH.md's coverage-gap pattern (every
on-device model here needs first-party verification, none of them are proven at 100% accuracy) means
skipping the review step is not an option, not just a nicety.

### 4.7 Gamification engine — reward completion, never suppression

```kotlin
enum class GamificationTrigger { INTERVENTION_WORKED, TODO_COMPLETED, HEALTH_TARGET_MET, CAPTURE_ORGANIZED }

data class GamificationEvent(val trigger: GamificationTrigger, val xpAwarded: Int, val timestamp: Long)

/** Streak is non-losable by design (RESEARCH.md §Expansion: gamified capture-to-organize layer) —
 *  a missed day pauses progress toward the next milestone, it never subtracts XP or resets to zero.
 *  This is a direct response to arXiv:2411.09706's finding that losable streaks independently
 *  increase anxiety/compulsive checking, not a UX nicety. */
class GamificationEngine(private val store: GamificationDao) {
    fun onTrigger(trigger: GamificationTrigger) {
        val xp = when (trigger) {
            GamificationTrigger.INTERVENTION_WORKED -> 15   // gated on FeedbackLoop's own ≥5% threshold — see §4.4
            GamificationTrigger.TODO_COMPLETED -> 10
            GamificationTrigger.HEALTH_TARGET_MET -> 10
            GamificationTrigger.CAPTURE_ORGANIZED -> 5
        }
        store.recordEvent(GamificationEvent(trigger, xp, System.currentTimeMillis()))
        store.addXp(xp)  // level-up logic reads cumulative XP; never decremented, never reset
    }
}
```

**Pre-ship self-audit (RESEARCH.md §Expansion: gamified capture-to-organize layer) — run this as an
actual checklist item before the app is considered demo-ready, not a suggestion:**
1. Does any mechanic penalize a *missed* day (lost streak, lost XP, red/warning color on a gap)? If
   yes, it fails the audit — redesign as a pause, not a loss.
2. Does any copy use urgency/loss-framing ("don't lose your streak!", "your level is at risk")? Using
   the taxonomy from "Dark Patterns at Scale" (arXiv:1907.07032) as the checklist, this counts as
   manipulative framing — rewrite as accomplishment-framing instead ("you're on a 5-day streak!").
3. Does the app ever reward *not* using a feature (e.g. bonus XP purely for low screen time, with no
   completed action behind it)? That's the exact pattern RESEARCH.md flags as conflicting with the
   project's own mission — remove it; XP must always trace to a completed action.
4. Run this checklist against the actual shipped copy/UI, not the design doc — the review in §3's
   "Day 6-7" final hours is where this happens for real, not a Sprint-0-only formality.

### 4.8 Masked tool selection — the "autonomous orchestration" decision point

This is the concrete implementation of §0.4's design rule: the model gets genuine autonomy over *what
it queries*, bounded by masking, schema validation, and a hard call cap — never a free-form loop that
plans its own sequence or decides when to stop. See RESEARCH.md §Expansion: flagship-hardware agentic
upgrade for why this specific boundary, not a looser one, is what the evidence supports.

```kotlin
/** The only five choices the model is ever offered at this decision point — a closed enum, not an
 *  open tool name the model generates freely. Function masking (RESEARCH.md: Octopus, Hammer) is
 *  what makes small-model tool selection reliable; an open vocabulary is exactly what the
 *  multi-step-orchestration failure numbers (HyperTool, Evoflux, TOBench) were measured on. */
enum class GoalContextSource { NOTES, TODOS, HEALTH_TARGETS, CALENDAR, CAPTURE_HISTORY }

data class SourceSelection(val sources: List<GoalContextSource>, val reasoning: String)

class MaskedSourceSelector(private val slm: SlmExplainer, private val maxCalls: Int = 3) {
    /** One masked, schema-validated decision — not a loop the model controls. `slm.selectSources`
     *  is constrained-decoded against the GoalContextSource enum (grammar/JSON-schema constrained
     *  generation, per RESEARCH.md's "Small Language Models for Agentic Systems" survey finding on
     *  guided decoding) so an invalid/hallucinated source name cannot come back at all. */
    fun select(triggerSignal: String, topSignal: String): SourceSelection {
        val raw = slm.selectSources(triggerSignal, topSignal, allowed = GoalContextSource.entries)
        val validated = raw.sources.filter { it in GoalContextSource.entries }  // defense in depth
        if (validated.isEmpty() || validated.size > maxCalls) {
            // Cap hit or empty/malformed response: fall back to the old fixed behavior, don't retry
            // indefinitely — this is the guard against the documented "infinite agentic loop" failure
            // mode (RESEARCH.md: arXiv:2607.01641), not a bug to silently ignore.
            return SourceSelection(GoalContextSource.entries, reasoning = "fallback: query all sources")
        }
        return SourceSelection(validated, raw.reasoning)
    }
}
```

`GoalContext.retrieve()` (§4.5) takes the resulting `SourceSelection` and only queries those sources —
everything downstream of this call (the flat-bullet concatenation, the single-sentence explanation
prompt) is unchanged from §4.5/§4.3. The model never decides to call this selector again, never decides
the loop is "not done yet," and never invokes a tool outside this fixed five-option menu — that
boundary is the whole design, not an implementation detail to loosen once it's working.

---

## 5. Permissions checklist (pre-grant on the demo device — do this before you're on stage)

| Permission | Grant path | Why it's not a runtime dialog |
|---|---|---|
| Usage access (`UsageStatsManager`) | Settings → Apps → Special access → Usage access | Requires manual toggle, no `requestPermissions()` path exists |
| Notification access (`NotificationListenerService`) | Settings → Apps → Special access → Notification access | Same — manual only |
| Full-screen intent (`USE_FULL_SCREEN_INTENT`) | Auto-granted on install for targetSdk ≤ 33; needs manual grant on 34+ | Check target SDK against the loaner phone's Android/OriginOS version day 1 |
| Camera (`CAMERA`) | Standard runtime `requestPermissions()` dialog | Needed for the capture-flow's photo path (§4.6) — dialog-based, but still worth pre-granting before demo to avoid an on-stage prompt |
| **No `INTERNET` permission requested by the base app** | N/A — just don't declare it in the base manifest | This is the demo-able privacy proof — see §5.1 for how Calendar's permission stays separate |

Build this into a literal pre-demo checklist you run on the actual loaner device, not just your dev
phone — RESEARCH.md flags this as a common failure mode.

### 5.1 Calendar as an opt-in module (not a base permission)

Ship Calendar sync as a feature module requested behind its own "Connect calendar (optional)" screen,
using OAuth (Google Calendar API) only when the user taps that specific button — not at app install
or first launch. Concretely: a separate Gradle module or at minimum a separate settings-gated code
path, so the base APK's manifest stays auditable as "no network" and the calendar path is visibly
additive, not load-bearing. This is what makes the demo script's "everything you saw works offline;
calendar only adds context" narration literally true rather than a talking point — see §6.

---

## 6. Demo script (target: under 4:30)

1. **(0:00-0:30)** Open Settings, show no `INTERNET` permission, toggle **airplane mode** on camera.
2. **(0:30-1:15)** Show the always-available "transparency panel" (raw signal counts + z-scores +
   last few interventions + measured effect) — explicitly frame this as "we score ourselves the way
   HackTracker scores us: device data, not self-report."
3. **(1:15-2:00)** Trigger an overload state live (either genuinely by rapid app-switching on stage,
   or a debug "simulate overload" button if live triggering is too slow/unreliable) — overlay swipes
   in, SLM sentence appears grounded in a real todo/health target (goal-context, still airplane-mode,
   no calendar needed), spoken via TTS. If the transparency panel shows the model's masked source
   choice (§4.8 — e.g. "checked: todos, health targets · skipped: calendar, notes"), point at it
   explicitly: "the model decides what to check, but only from a fixed, validated list — it can't go
   off and do something we didn't authorize."
4. **(2:00-2:45)** Photograph a printed schedule on stage, circle one item with a finger (freeform
   capture, still airplane-mode — the vision pipeline is on-device), watch it get cropped/rectified/
   OCR'd, confirm it on the review screen as a new todo — then show the XP award and streak/level tick
   up. Narrate explicitly: "the gamification only rewards this — an action actually completed — never
   just closing the phone."
5. **(2:45-3:15)** Toggle airplane mode **off**, tap "Connect calendar (optional)," show a calendar
   event pull in as an extra context bullet on the next trigger — narrate explicitly: "everything you
   just saw works fully offline; this is opt-in and adds context, it's never required."
6. **(3:15-3:50)** Dismiss, show the feedback loop panel: pre/post effect size logged, bandit weight
   update visible.
7. **(3:50-4:30)** One slide: Dotsin-inspired novelty framing (regime-aware baseline, intervention-
   as-experiment, Bayesian cold start, goal-grounded explanations, gamified capture-to-organize with a
   non-losable-streak design) — 4-5 bullets, not a research lecture.

Have a **debug "simulate overload" button** as a fallback trigger — live on-stage triggering of real
usage signals is a demo-risk, don't rely on it alone. Same for capture: have a pre-photographed sample
schedule ready in case stage lighting makes a live photo unreliable.

---

## 7. Stretch goals (only after §3's final integration exit criterion is met)

In priority order — stop at whichever you reach when battle time runs out:

1. **Tier 2 tiny classifier** replacing the hand-tuned weighted sum with a small on-device logistic
   regression or decision tree trained on your own dogfooded label data (you labeling your own
   "felt overloaded" moments over the prep week) — still tiny enough to run as pure arithmetic, no
   new inference runtime needed.
2. **LoRA fine-tune the SLM** on a few hundred synthetic (structured-signal → sentence) pairs,
   following the RadLite recipe (RESEARCH.md #7) — only attempt this if the backend-native workstream's
   prompt-engineered zero/few-shot approach is visibly unreliable, since it's the highest-risk,
   highest-setup-cost item on this list.
3. **A 3rd/4th bandit arm: light friction** — a short confirmation delay (e.g. 3 seconds, tap-to-
   confirm) before the focus layer can be dismissed. InteractOut (arXiv:2401.16668) found friction-
   based mechanisms beat timed lockout by an *additional* 15.6% usage-time cut and 16.5% fewer opens
   — cheap to build, and gives the bandit a qualitatively different lever from "show UI"/"show
   notification."
4. **True `SYSTEM_ALERT_WINDOW` overlay** instead of full-screen-intent activity, for a more literal
   "swipes in over the home screen" effect — only after the MVP overlay is rock solid, since this
   permission class is more failure-prone on stage.
5. **Offline `SpeechRecognizer` for a spoken dismiss/snooze reply** — adds a second voice touchpoint,
   nice-to-have for the HackTracker "voice" line, not required (TTS alone already covers it).
6. **Intent-vs-actual-use gap as a signal**, from arXiv:2606.08965 (Jun 2026, genuinely fresh —
   unlikely other teams found it): the gap between a session's intended and actual length predicts
   "regretful" use far better than raw duration. Infer intended duration from the historical
   per-app session-length distribution (no need to ask the user directly, which would add friction to
   every app open) and feed the gap into the classifier as a signal alongside unlocks/latency/switches.
   Only attempt after §3's final integration exit criterion is met — it needs its own tuning pass.
7. **Note embeddings via EmbeddingGemma-300M** (GoalContext §4.5) — semantic retrieval over free-text
   notes only, on-device cosine top-k, no ANN library needed at personal-corpus scale (dozens to low
   hundreds of notes). Structured todos/health targets (frontend workstream) don't need this — only
   notes do.
8. **Calendar OAuth module** (§5.1) — highest setup cost on this list (Google Cloud Console project,
   OAuth consent screen, Calendar API scopes) relative to its demo payoff; attempt only after 7 is
   solid, since the demo's strongest beat (goal-grounded explanation, offline) already works without it.
9. **DocSLM-based schedule photo/PDF parsing** (RESEARCH.md §Expansion) — replaces manual todo/schedule
   entry with an uploaded timetable photo. Unverified for phone deployment and for timetable-specific
   layouts (6-star repo, general-document benchmark only) — Finale-window material, not city-battle.
10. **Dedicated image embedding for captured items via MobileCLIP2** (RESEARCH.md §Expansion: gamified
    capture-to-organize layer) — only attempt if measurement shows OCR-text-through-EmbeddingGemma
    (the MVP default, §4.6) is losing too much of a captured schedule's layout/structure for retrieval
    to work well. The literature is split on whether this is needed at all for this content type
    (DSE/UniSE argue yes, CIVIL argues no) — this is a measured upgrade, not a default build target.

---

## 8. Open risks carried over from RESEARCH.md

See RESEARCH.md §"Open questions / risks" for the full list — the most time-sensitive are:
**(a)** no literature-verified phone-class Snapdragon NPU inference latency for a 4-8B agentic model
(Sprint-0-era spike is the first real measurement — see §0.4/§2); **(b)** no literature-backed threshold
for app-switching/fragmentation signals (expect hand-tuning against real usage, isolated in one
easily-editable config so late calibration doesn't risk breaking anything else); **(c)** running
multiple on-device models simultaneously (SLM generator + embedder + capture-pipeline's
segmentation/dewarp/OCR stack) is untested on phone hardware even though the ~4-6GB combined RAM
estimate looks comfortable against the confirmed 16GB flagship — backend-native should check combined
memory pressure AND concurrent-load latency early (RESEARCH.md flags memory *bandwidth*, not just
capacity, as a distinct real risk), not only per-model latency in isolation; **(d)** resist the
temptation to make the SLM reason jointly across notes/todos/calendar/health in one prompt, or to let it
freely plan multi-step tool sequences beyond the masked §4.8 selection point — the literature says even
frontier models do both of these badly (34.5% pass@1 on fusion, 32-36% on multi-step orchestration),
keep retrieval-per-source, flat concatenation, and masked/capped tool selection only (§4.5/§4.8);
**(e)** no paper does freeform-scribble-to-clean-crop plus document rectification as one studied task,
so the capture pipeline (§4.6) is first-party integration work between two separately-sourced models,
not a single proven recipe — budget real testing time for the composed pipeline, not just each model in
isolation; and **(f)** gamification is in real, evidence-backed tension with the app's own anti-overload
mission — the non-losable-streak design rule and the pre-ship self-audit (§4.7) are the mitigation, and
skipping that audit under time pressure during the battle is the most likely way this risk actually
materializes.
