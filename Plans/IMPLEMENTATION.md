# Implementation Plan — On-Device Overload Agent
**iQOO City Battles 2026 · Open Innovation · solo build, Claude Code as pair-programmer**

Companion to `RESEARCH.md` — read that first for *why* each component is built the way it is below.
This doc is the *how*: architecture, day plan, permissions, and code skeletons.

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
│ SlmExplainer        │          │ FocusOverlay (full-screen     │
│ Gemma 3 1B QAT       │          │ intent activity)               │
│ via runtime adapter   │───────▶│ muted UI, 3 essential apps,   │
│ → one sentence        │  text   │ explanation text + TTS voice  │
└─────────┬─────────┘          └───────────────┬──────────────────┘
          ▲
          │ flat context bullets (no fusion — see §0.1)
┌─────────┴─────────────────────────────────────────────────────┐
│  GoalContext (retrieval-per-source, combined only at prompt time)│
│  ├─ Notes: EmbeddingGemma-300M, on-device cosine top-k            │
│  ├─ Todos / HealthTargets: Room, direct field filter (no embed)  │
│  └─ Calendar (opt-in, OAuth): time-range filter (no embed)        │
└─────────────────────────────────────────────────────────────────┘
                                                 │ user dismisses / cooldown ends
                                                 ▼
                                ┌──────────────────────────────┐
                                │ FeedbackLoop                    │
                                │ re-measure signals post-window, │
                                │ log pre/post effect size,        │
                                │ update bandit + thresholds       │
                                └──────────────────────────────┘
```

No component in the core loop (everything above except the optional Calendar source) makes a network
call. The base app's `AndroidManifest.xml` declares **no `INTERNET` permission at all** — checkable by
a judge in Settings → App Info in about 10 seconds. Calendar sync is a separate opt-in module with its
own permission grant, not bundled into the base install — see §5.1.

---

## 2. Stack decisions

Full evidence chain (numbers + logic, including what's *not* backed by a citation and why) is in
RESEARCH.md § "Decision justification" — this table is the summary.

| Component | Choice | Why |
|---|---|---|
| Signal collection | `UsageStatsManager`, `NotificationListenerService`, `ACTION_USER_PRESENT` broadcast | All native Android, metadata-only, no special hardware |
| Baseline storage | Room (SQLite) | Local-only, no sync, trivial to demo-reset between runs |
| Classifier | Rule-based Welford z-score, hand-tuned thresholds | O(log n) vs O(n) sample-complexity theory (arXiv:2302.02334) + a direct empirical analog hitting precision=1.00/recall=1.00 at 14-day data scale (arXiv:2604.08581) both favor rule-based at this project's data volume — not just a time-budget shortcut |
| On-device SLM | **Gemma 3 1B IT, Google's QAT Q4_0 GGUF (~1GB)**, via llama.cpp JNI | 1GB file, 32K ctx, HellaSwag 62.3/PIQA 73.8/ARC-e 73.0 — best verified param/quality/quant fit at this budget. No published QAT-vs-bf16 quality delta though (model card is qualitative only) — see RESEARCH.md §Decision justification |
| SLM harness | Start from upstream **llama.cpp's maintained `examples/llama.android` binding**, behind ATARI's runtime-independent explanation contract | Upstream already implements private-file GGUF loading, chat templates, Kotlin `Flow` token streaming, and benchmarking; PhoneLM uses its separate `mllm` runtime and is not the Gemma/llama.cpp harness |
| Voice output | Android `TextToSpeech` (offline engine) | Zero extra permission, covers HackTracker's "voice" line without touching the mic |
| Overlay UI | `USE_FULL_SCREEN_INTENT` activity (MVP) → `SYSTEM_ALERT_WINDOW` overlay (stretch) | Full-screen intent is far lower permission-risk for a live demo; upgrade only if time remains |
| Dev bridge | Office Kit, paired for the whole build | Screen mirror for on-device debugging, file transfer for pulling logs off the loaner phone — scored on real usage, use it don't fake it |
| Note embeddings | **EmbeddingGemma-300M**, GGUF or q4 ONNX | SOTA <500M on MTEB, verified running on-device on Android in a real RAG system (MAM-AI) — see RESEARCH.md §Expansion. Fallback: Snowflake Arctic-Embed-XS (22.5M) if RAM is tight |
| Todos / health targets | Room, direct structured queries — **no embeddings** | They're structured records (deadline, metric, threshold) — a field filter is cheaper and more reliable than semantic search over the same content |
| Cross-source combination | Flat context bullets concatenated at prompt time — **no joint fusion/reasoning** | Literature (Setoka, Claw-Anything) shows even frontier models struggle at open-ended multi-source fusion (34.5% pass@1) — don't attempt it at hackathon scale |
| Calendar | Google Calendar API via OAuth, **opt-in module, separate permission** | Only component needing network/auth — architected as additive so the core loop's zero-`INTERNET` claim stays literally true |

**Runtime gate:** `llama.cpp` remains the primary GGUF path because Google publishes the selected
Gemma 3 1B QAT artifact directly in that format and upstream now maintains an Android binding.
LiteRT-LM has since matured into an official Android runtime with stable Kotlin/C++ APIs and documented
Gemma 3 1B support, so it is the comparison candidate rather than a dismissed path. Run the same
prompt set through both on the target iQOO device; keep the adapter with the best measured latency,
memory, thermal behavior, build reliability, and valid-output rate. See `research/model-runtime.md`.

---

## 3. Day-by-day plan

### Day 1 — Environment + model spike
- Confirm pre-build rules with organizers (§0).
- Set up Android Studio, pair Office Kit to the loaner/dev phone, confirm screen mirror + file
  transfer work (this is graded usage — start the clock on it now, not day 6).
- Build upstream `llama.cpp/examples/llama.android`, then integrate its library behind ATARI's
  `ModelRuntime` boundary rather than copying the sample application wholesale.
- After accepting the Gemma terms, download `google/gemma-3-1b-it-qat-q4_0-gguf`, load it through
  the adapter, and measure
  cold-load time and tokens/sec on the actual loaner phone's Snapdragon SoC. **This number does not
  exist in any paper — you are the first data point.** If it's too slow, fall back to
  `Qwen2.5-0.5B-Instruct-GGUF` (smaller, from RESEARCH.md "Also relevant").
- **Spend real time on the few-shot prompt (§4.3), not just model loading.** RESEARCH.md's Time2Stop
  finding (arXiv:2403.05584) measured +53.8%/+11.4% receptivity gain from adding explanations to an
  intervention — the explanation's quality is plausibly the highest-leverage thing built all week, so
  don't treat prompt design as an afterthought once the model loads. Budget at least half of Day 1's
  remaining time to iterating the 3-4 few-shot examples against real signal snapshots from your own
  phone, not just confirming the harness compiles.
- Exit criterion: a structured JSON string in → one sentence out, running fully offline on-device,
  in under ~3 seconds.

### Day 2 — Signal collectors
- `UnlockTracker`: `BroadcastReceiver` on `ACTION_USER_PRESENT`, persisted via a `WorkManager`
  periodic worker (Android kills raw long-lived receivers).
- `AppSwitchTracker`: `UsageStatsManager.queryEvents()`, count `MOVE_TO_FOREGROUND` transitions in
  rolling windows.
- `NotifLatencyTracker`: `NotificationListenerService`, log `onNotificationPosted` timestamp vs. the
  next unlock or `onNotificationRemoved` — **metadata only, never read notification text/content.**
- All three write into Room. Exit criterion: three tables filling with real timestamped events from
  your own phone over a few hours of normal use.

### Day 3 — Baseline + classifier
- Implement Welford online mean/variance per (hour_of_day, day_of_week) bucket per signal (code
  skeleton in §4 below).
- Implement the Bayesian cold-start blend (RESEARCH.md, Dotsin concept #3) with a hardcoded
  population-default prior per signal (pick defaults from your own week of dogfooding — there's no
  published number to use here, this is the project's own contribution).
- Wire up the rule-based classifier: weighted z-score sum, threshold → `OverloadEvent`.
- Exit criterion: forcing a synthetic burst of unlocks/switches on your dev phone visibly flips the
  classifier state, logged and observable (Logcat is fine at this stage).

### Day 4 — Orchestrator + overlay + TTS
- State machine (`NORMAL → OVERLOAD_DETECTED → INTERVENING → COOLDOWN`), cooldown timer, one-time
  consent screen on first launch (list exactly which signals are collected and why — this doubles as
  demo material for the privacy pitch).
- `FocusOverlayActivity`: full-screen intent, muted color scheme, 3 pinned "essential" apps
  (user-configurable in settings), explanation text from `SlmExplainer`.
- Wire `TextToSpeech` to speak the explanation when the overlay appears.
- Add simple structured entry screens for **todos and health targets** (Room-backed CRUD forms —
  deadline field on todos, metric+threshold on health targets). No embeddings needed for these, so
  this is cheap UI work, not an ML task — see §0.1.
- Exit criterion: end-to-end loop fires for real — collectors feed the classifier, classifier
  triggers the orchestrator, orchestrator shows the overlay with a real SLM-generated sentence
  that references at least one live todo/health-target when relevant, spoken aloud.

### Day 5 — Feedback loop + rehearsal
- `FeedbackLoop`: on cooldown end, re-pull the same signal window, compute pre/post effect size, log
  it, and update the epsilon-greedy weights over intervention variants (start with 2: "focus layer"
  vs. "single suggested-break notification"; add a 3rd "light friction" arm from §7 if time allows).
  Flag an intervention as "worked" at **≥5% signal reduction**, not a large swing — RESEARCH.md
  "Decision justification" shows real JITAI effect sizes cluster at 7-17%, so a high bar would make
  working interventions look like failures. A null result for one arm is valid bandit signal (down-
  weight it), not a bug to chase — see RESEARCH.md's Protégé-effect null-result caution.
- Pre-grant checklist as an actual runnable script/doc (`NotificationListenerService` and
  full-screen-intent-class permissions need manual Settings grants — see §5) — rehearse this on the
  loaner device specifically, not just your dev phone.
- Full airplane-mode dry run of the demo script (§6). Time it — target under 4 minutes.
- Exit criterion: you can hand the phone to someone else, they toggle airplane mode on, force an
  overload state, and watch the full loop complete without you touching anything.

### Day 6-7 — The 30-hour battle
- **Green Light (both devices):** heavier work first — any Tier 2 stretch (see §7), threshold
  re-tuning against real battle-day usage, UI polish, LoRA experiment if time allows. Use laptop
  compute for anything Gradle/build-heavy.
- **Red Light (phone-only via Office Kit):** the app itself must already be feature-complete and
  running fully on-device by the time Red Light windows hit — Red Light changes *how you drive the
  laptop* (remote control via Office Kit), not what the app needs to do. Use these windows for
  on-device debugging, log pulling, and demo rehearsal, since that's naturally phone-first work.
- Final hours: freeze features, rehearse the pitch (§6), confirm permissions are pre-granted on the
  actual demo device, confirm `INTERNET` permission is absent from the manifest as a last check.

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
reliability at 1B scale — budget Day 1 spike time for this, not just the model-loading spike.

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

---

## 5. Permissions checklist (pre-grant on the demo device — do this before you're on stage)

| Permission | Grant path | Why it's not a runtime dialog |
|---|---|---|
| Usage access (`UsageStatsManager`) | Settings → Apps → Special access → Usage access | Requires manual toggle, no `requestPermissions()` path exists |
| Notification access (`NotificationListenerService`) | Settings → Apps → Special access → Notification access | Same — manual only |
| Full-screen intent (`USE_FULL_SCREEN_INTENT`) | Auto-granted on install for targetSdk ≤ 33; needs manual grant on 34+ | Check target SDK against the loaner phone's Android/OriginOS version day 1 |
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

## 6. Demo script (target: under 4 minutes)

1. **(0:00-0:30)** Open Settings, show no `INTERNET` permission, toggle **airplane mode** on camera.
2. **(0:30-1:30)** Show the always-available "transparency panel" (raw signal counts + z-scores +
   last few interventions + measured effect) — explicitly frame this as "we score ourselves the way
   HackTracker scores us: device data, not self-report."
3. **(1:30-2:15)** Trigger an overload state live (either genuinely by rapid app-switching on stage,
   or a debug "simulate overload" button if live triggering is too slow/unreliable) — overlay swipes
   in, SLM sentence appears grounded in a real todo/health target (goal-context, still airplane-mode,
   no calendar needed), spoken via TTS.
4. **(2:15-2:45)** Toggle airplane mode **off**, tap "Connect calendar (optional)," show a calendar
   event pull in as an extra context bullet on the next trigger — narrate explicitly: "everything you
   just saw works fully offline; this is opt-in and adds context, it's never required."
5. **(2:45-3:25)** Dismiss, show the feedback loop panel: pre/post effect size logged, bandit weight
   update visible.
6. **(3:25-4:00)** One slide: Dotsin-inspired novelty framing (regime-aware baseline, intervention-
   as-experiment, Bayesian cold start, goal-grounded explanations) — 3-4 bullets, not a research lecture.

Have a **debug "simulate overload" button** as a fallback trigger — live on-stage triggering of real
usage signals is a demo-risk, don't rely on it alone.

---

## 7. Stretch goals (only after §3's Day 5 exit criterion is met)

In priority order — stop at whichever you reach when battle time runs out:

1. **Tier 2 tiny classifier** replacing the hand-tuned weighted sum with a small on-device logistic
   regression or decision tree trained on your own dogfooded label data (you labeling your own
   "felt overloaded" moments over the prep week) — still tiny enough to run as pure arithmetic, no
   new inference runtime needed.
2. **LoRA fine-tune the SLM** on a few hundred synthetic (structured-signal → sentence) pairs,
   following the RadLite recipe (RESEARCH.md #7) — only attempt this if Day 1's prompt-engineered
   zero/few-shot approach is visibly unreliable, since it's the highest-risk, highest-setup-cost item
   on this list.
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
   Only attempt after Day 5's core-loop exit criterion is met — it needs its own tuning pass.
7. **Note embeddings via EmbeddingGemma-300M** (GoalContext §4.5) — semantic retrieval over free-text
   notes only, on-device cosine top-k, no ANN library needed at personal-corpus scale (dozens to low
   hundreds of notes). Structured todos/health targets from Day 4 don't need this — only notes do.
8. **Calendar OAuth module** (§5.1) — highest setup cost on this list (Google Cloud Console project,
   OAuth consent screen, Calendar API scopes) relative to its demo payoff; attempt only after 7 is
   solid, since the demo's strongest beat (goal-grounded explanation, offline) already works without it.
9. **DocSLM-based schedule photo/PDF parsing** (RESEARCH.md §Expansion) — replaces manual todo/schedule
   entry with an uploaded timetable photo. Unverified for phone deployment and for timetable-specific
   layouts (6-star repo, general-document benchmark only) — Finale-window material, not city-battle.

---

## 8. Open risks carried over from RESEARCH.md

See RESEARCH.md §"Open questions / risks" for the full list — the most time-sensitive are:
**(a)** no literature-verified Snapdragon inference latency for Gemma 3 1B GGUF (Day 1 spike is the
first real measurement); **(b)** no literature-backed threshold for app-switching/fragmentation
signals (expect hand-tuning against your own week of usage, isolated in one easily-editable config
so late calibration doesn't risk breaking anything else); **(c)** running two on-device models
simultaneously (generator + embedder, ~1.3GB) is untested on the loaner device — check this on Day 1
alongside (a); and **(d)** resist the temptation to make the SLM reason jointly across notes/todos/
calendar/health in one prompt — the literature says even frontier models do this badly (34.5% pass@1),
keep retrieval-per-source and flat concatenation only (§4.5).
