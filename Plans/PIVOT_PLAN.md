# PIVOT_PLAN — ATARI → Capture-Structure-Remind
**Companion to IMPLEMENTATION.md · Full critique + revised, demo-safe architecture**

---

## Part 1 — Critique of the current plan

### 1.1 What's genuinely good — keep this
- **Layer-based git ownership (§0.2).** Real engineering judgment: changed-file sets not overlapping is what prevents conflicts, not "communication discipline." Keep as-is.
- **Masked/schema-validated decision points (§4.8).** This is the correct pattern for small-model reliability, and it's grounded in your own cited evidence (Octopus, Hammer — narrow candidate sets work; open loops don't). The mistake isn't this pattern — it's that it's currently applied to only *one* decision point when it should be the template for every model-touches-the-world moment in the app (see 2.3 below).
- **Confirm-before-persist on capture (§4.6).** Correct instinct, should be non-negotiable everywhere the model writes something real (see 2.4).
- **Demo script fallback buttons.** Recognizing that live signal-triggering is a demo risk and building a manual override is exactly right.
- **The risk section (§8).** Unusually honest for a plan doc — it already names most of what's wrong. The failure isn't lack of awareness, it's that the plan doesn't act on its own risk list by cutting scope.

### 1.2 The core structural problem: four scope expansions stacked on one MVP
§0.1–§0.4 each independently make sense and each is individually well-argued. Stacked together, in 5 prototype days + one 30-hour battle, with 2 backend devs, they add up to:
- A rule-based signal/baseline engine
- A 4B-parameter SLM running via a custom llama.cpp JNI harness
- A 300M embedding model for notes
- A segmentation model (EdgeSAM) + a dewarping model (DocScanner) + an OCR model (PP-OCR) — three more models, none benchmarked on this hardware in any paper
- A masked tool-selection layer
- A gamification state machine with its own dark-pattern audit
- An optional OAuth calendar module

That's **five separate on-device model integrations** owned mostly by one dev (backend-native), each of which the plan itself admits has zero verified numbers on this hardware. §8(c) already flags "running multiple on-device models simultaneously... is untested" as a real risk — but the architecture still treats concurrent residency as the default assumption rather than something to design around.

**The actual risk isn't any one model. It's that the demo depends on all five working together, live, on stage, simultaneously.** That's the single biggest threat to this project working at all, and it's not solved by better prompt engineering — it's solved by cutting what has to be true at demo time.

### 1.3 Overload detection is infrastructure, not the pitch
The Welford/z-score/orchestrator stack (§1 top half, §4.1–§4.2) is solid, testable, deterministic engineering. But it detects a *symptom*, not a *fix*. It should stay in the app as one trigger among several for surfacing help — not the thing being pitched to judges as the solution.

### 1.4 Everywhere the SLM's job is underspecified, it should be a closed enum
Three places in the current plan ask the SLM to do something open-ended without the §4.8 treatment:
- "Makes bite-sized tasks" — open-ended decomposition, no schema, no cap.
- Difficulty scoring for gamification — undefined.
- SlmExplainer's "top_signal" reasoning — fine as-is (single sentence, fixed template), but nothing stops future scope creep here either.

Any place the model outputs something that becomes real app state or a real tool call needs the same treatment §4.8 already proved out: closed enum, schema validation, hard cap, deterministic fallback on malformed output, no retry loop.

### 1.5 Concurrent model memory is treated as a risk to measure, not a design constraint to avoid
§3 backend-native workstream literally schedules "test them resident together" as a task, with a hopeful "~4-6GB against 16GB available" estimate that the plan itself calls a hypothesis. For a 30-hour battle demo, this is backwards — you don't want to *discover* whether concurrent residency works under stage conditions, you want to have architected around ever needing it.

---

## Part 2 — Pivot: what changes

### 2.1 Reframe the pitch
**Old:** "We detect phone overload and intervene."
**New:** "We turn messy input — photos, notes, spoken thoughts — into reminders and alarms that actually fire, with the app judging task difficulty so effort gets rewarded fairly."

Overload detection demotes to **one optional trigger** for *when* the transparency panel surfaces proactively. It is no longer load-bearing for the demo's core story. This single change removes the pressure to prove the Welford/z-score engine live on stage — it can run quietly in the background and be shown, not depended on.

### 2.2 Sequential model loading, not concurrent residency
Replace "test everything resident together" with an architectural rule: **only one heavy model is loaded at a time.**
- Capture flow: vision pipeline loads → produces text → **unloads** → EmbeddingGemma loads only if semantic note search is invoked → unloads.
- SLM (Qwen3-4B) loads only at the decision points that need it (difficulty scoring, decomposition, explanation) → unloads after.
- This converts an unverified "peak concurrent RAM" risk into a controlled, testable "worst single model's footprint" risk — benchmarkable reliably in Sprint 0's first day, on the actual device, with no surprises left for the battle window.
- Cost: added latency from load/unload cycles. Acceptable, bounded, demo-predictable. An OOM crash or thermal throttle live on stage is not.

### 2.3 Extend the masked-enum pattern to every model decision point
Three enums, same defense-in-depth pattern as §4.8 (constrained decoding + post-hoc filter + fallback-on-malformed, never a retry loop):

```kotlin
enum class DifficultyTier { TRIVIAL, LIGHT, MODERATE, HEAVY }   // XP mapping is deterministic app code

data class SubtaskSpec(val title: String, val estimatedMinutes: Int, val tier: DifficultyTier)
data class DecompositionResult(val subtasks: List<SubtaskSpec>)  // hard cap: max 4 subtasks, else fallback = no decomposition

enum class TaskTool { SET_REMINDER, SET_ALARM, START_TIMER, ADD_TODO, NONE }
```

Rule stated once, applied everywhere: **the SLM never emits free text that becomes state. It always emits a validated selection from a closed set the app defined in advance.**

### 2.4 Confirm-before-write, universally, no exceptions
Every one of these requires a user tap before it becomes real:
- A captured item saved as Note/Todo/HealthTarget (already in §4.6 — correct, keep).
- A subtask spec turned into a reminder/alarm/timer.
- A difficulty tier turned into an XP award (auto-award is fine here — XP has no real-world consequence, unlike an alarm firing).

The dividing line: **if a wrong output costs the user something in the physical world (a 3am alarm, a missed reminder), it needs confirmation. If it only costs a slightly-off game number, it can be automatic.**

### 2.5 Cut list — what leaves the MVP, moves to stretch, or is dropped

| Item | Current status | Pivot status | Why |
|---|---|---|---|
| EdgeSAM segmentation | Core capture pipeline | **Stretch** — MVP uses simple bounding-box crop from the scribble's convex hull | One fewer model to integrate/benchmark before the battle; a bounding-box crop is good enough for "circle an item, get it extracted" |
| DocScanner dewarp | Core capture pipeline | **Stretch** — MVP handles screenshots and near-flat photos only, flags heavily-angled photos as low-confidence for manual review | Same reasoning — cut a model, not a feature; the review step already planned in §4.6 absorbs the quality gap |
| Qwen3-8B eval path | Parallel spike | **Dropped** — commit to Qwen3-4B Day 1, no comparison spike | A runtime eval spike that might not even complete before Sprint 0 ends is scope, not infrastructure |
| Calendar OAuth module | §0.1 core, §5.1/§7 stretch (contradictory) | **Pure stretch, untouched until final polish hours** | Only network/auth-dependent piece; zero relation to the new core pitch |
| Concurrent-model memory testing | Scheduled backend-native task | **Removed** — replaced by 2.2's sequential-load rule | Testing an assumption you can design away is wasted time under a hard deadline |
| Overload detection engine | Core loop, headline feature | **Kept, demoted** — background signal, secondary trigger, shown not pitched | Still good engineering, just not the star |

### 2.6 Revised priority ladder (what must work, in order)
1. **Capture → structured item → confirmed reminder/alarm.** This alone is a demoable, judge-legible product. Ship this first, make it bulletproof.
2. **SLM difficulty scoring + XP on completion.** Adds the gamification story, low real-world risk (2.4).
3. **SLM one-line explanation grounded in GoalContext** (notes/todos/health — no calendar). Adds the "understands your context" story.
4. **Task decomposition into subtasks with tool calls.** Highest complexity item — attempt only once 1–3 are solid.
5. **Overload detection as a background trigger for surfacing the transparency panel.** Bonus, not load-bearing.
6. **Calendar opt-in module.** Final-hours polish only, per 2.5.

### 2.7 Team split — same ownership model, redistributed scope

| Dev | Still owns | No longer owns (this cycle) |
|---|---|---|
| Frontend | Capture UI (scribble → bounding-box crop preview, no SAM dependency), review/edit screen, gamification UI, transparency panel (now secondary, not hero screen) | Calendar connect screen (moved to stretch-only backlog) |
| Backend-Native | SLM harness (Qwen3-4B only, sequential load per 2.2), PP-OCR bridge, signal collectors, TTS | EdgeSAM, DocScanner, concurrent-memory test task, Qwen3-8B spike |
| Backend-Engine | Baseline/classifier/orchestrator (unchanged, now feeding a secondary trigger), GoalContext retrieval, CapturedItemParser, GamificationEngine + difficulty-tier mapping, the three new masked enums from 2.3 | Calendar source in GoalContext (nullable already — stays nullable, simply never gets implemented this cycle) |

Net effect: backend-native's workload drops from five model integrations to two (SLM + OCR), which is the single change most likely to make the 30-hour battle window actually achievable.

### 2.8 Sprint 0 contract changes
Add to the original contract set:

```kotlin
enum class DifficultyTier { TRIVIAL, LIGHT, MODERATE, HEAVY }
enum class TaskTool { SET_REMINDER, SET_ALARM, START_TIMER, ADD_TODO, NONE }
data class SubtaskSpec(val title: String, val estimatedMinutes: Int, val tier: DifficultyTier)
```

Remove from Sprint 0's required fakes: `EdgeSamService`, `DocScannerService`, calendar OAuth fakes — not needed until/unless their stretch items are reached.

### 2.9 Revised demo script beat (replaces old beat 3–4)
1. Photograph/circle a schedule item (bounding-box crop, no SAM) → OCR → review screen → confirm as todo with a reminder time.
2. Show the SLM's difficulty tier assignment and XP award on completion — narrate: "the model only ever picks from four fixed difficulty levels, it can't invent a score."
3. Trigger the transparency panel manually (fallback button) to show the background overload signal exists — one line, not the centerpiece.
4. If time remains: show decomposition on a heavier task, each subtask offering a tool-call chip (reminder/alarm/timer) the user taps to confirm.

---

## Part 3 — One-line summary of the pivot
Stop trying to prove five models work together live under stage pressure. Cut to two on-device models (SLM + OCR), load them sequentially not concurrently, extend the one design pattern that's already working (masked enums, confirm-before-write) to every place the model touches real state, and let overload detection be a quiet supporting signal instead of the thing the whole demo has to prove.

---

## Part 4 — Build status against this plan

The app is built **model-free**: every on-device model (SLM, embedder, OCR) sits behind an interface with a
deterministic placeholder implementation, so the entire product works end-to-end today and each model can be
dropped in later without touching UI or engine code. See `lib/core/services/placeholders/README.md`.

| Priority (2.6) | Status |
|---|---|
| 1. Capture → structured item → confirmed reminder/alarm | Built (OCR behind `OcrService` placeholder) |
| 2. Difficulty scoring + XP on completion | Built (behind `DifficultyScorer` placeholder) |
| 3. One-line explanation grounded in GoalContext | Built (behind `SlmExplainer` placeholder) |
| 4. Task decomposition into subtasks with tool calls | Built (behind `TaskDecomposer` placeholder) |
| 5. Overload detection as background trigger | Built, demoted to the transparency panel |
| 6. Calendar opt-in module | Not started — stretch only, per 2.5 |
