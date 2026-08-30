# ARCHITECTURE — ATARI post-pivot
**A JITAI system: capture→structure→remind is the core loop; overload detection is one of several decision-point triggers.**

---

## 1. JITAI framing, stated once, applied everywhere

Every component below is one of five JITAI parts. Naming this explicitly is what keeps the system
legible instead of accreting ad-hoc "AI features":

| Part | Rule in this app |
|---|---|
| Decision point | A fixed, enumerable set of moments — never "whenever the model feels like it" |
| Tailoring variables | Structured data only (z-scores, bullets, tiers) — never raw free text handed to the model ungoverned |
| Decision rule | Either deterministic code (Orchestrator, cooldown) or a masked/schema-validated model call — never open generation |
| Intervention option | A closed enum the decision rule picks from — never an invented action |
| Outcome | Logged, measured, feeds back into the decision rule (bandit weights) — every intervention is falsifiable |

---

## 2. Layered architecture

```
┌───────────────────────────────────────────────────────────────────────┐
│ DECISION POINTS (JITAI: when the system may act — fixed, enumerable)  │
│  A. Capture-flow completion   (primary, user-initiated)               │
│  B. Task/todo due-soon        (scheduled, WorkManager)                │
│  C. Overload signal fires     (background, secondary — §3 below)      │
│  D. Manual "simulate/check"   (debug + demo fallback)                 │
└──────────────────────────────┬──────────────────────────────────────────┘
                                │ TailoringVariables (structured, typed)
                                ▼
┌───────────────────────────────────────────────────────────────────────┐
│ DECISION RULES                                                          │
│  Deterministic layer (no model):                                        │
│   Orchestrator state machine · cooldown · InterventionBandit            │
│  Model-assisted layer (masked, schema-validated, single-shot):          │
│   MaskedSourceSelector(§4.8) · DifficultyClassifier · TaskDecomposer    │
│   → every model call here returns a value from a CLOSED ENUM,           │
│     never free text; malformed/oversized output → deterministic         │
│     fallback, never a retry loop                                        │
└──────────────────────────────┬──────────────────────────────────────────┘
                                │ InterventionSpec (one of the closed options below)
                                ▼
┌───────────────────────────────────────────────────────────────────────┐
│ INTERVENTION OPTIONS (closed enum — the only things the app can DO)   │
│  ┌─────────────┐ ┌──────────────┐ ┌───────────────┐ ┌────────────┐   │
│  │ SET_REMINDER│ │ SET_ALARM    │ │ START_TIMER   │ │ SHOW_       │   │
│  │             │ │              │ │               │ │ OVERLAY     │   │
│  └──────┬──────┘ └──────┬───────┘ └──────┬────────┘ └──────┬──────┘   │
│         │  every branch → CONFIRM-BEFORE-WRITE gate (user taps) ──┘   │
│         │  except XP award, which has no real-world consequence       │
└─────────┼──────────────────────────────────────────────────────────────┘
          │ user confirms
          ▼
┌───────────────────────────────────────────────────────────────────────┐
│ OUTCOME LOGGING (JITAI: proximal + distal)                             │
│  FeedbackLoop: re-measure signals post-window → effect size            │
│  GamificationEngine: completion → XP (difficulty-tier-scaled)          │
│  → both write back into InterventionBandit's weights (decision rule    │
│    layer above) — the loop closes here, this is what makes it a        │
│    measured system and not just a rule-based nag                       │
└───────────────────────────────────────────────────────────────────────┘
```

---

## 3. The core loop (what the demo is actually built on)

```
┌──────────────┐   scribble    ┌───────────────┐   OCR text   ┌──────────────────┐
│ Camera /     │──────────────▶│ Bounding-box   │─────────────▶│ PP-OCR (on-device)│
│ screenshot   │               │ crop (no SAM   │              │                    │
│              │               │ in MVP — §2.5) │              └─────────┬──────────┘
└──────────────┘               └────────────────┘                        │ raw text
                                                                            ▼
                                                              ┌─────────────────────────┐
                                                              │ CapturedItemParser        │
                                                              │ heuristic type/deadline   │
                                                              │ guess — NOT a 2nd model   │
                                                              └───────────┬───────────────┘
                                                                          │ CapturedItem
                                                                          ▼
                                                              ┌─────────────────────────┐
                                                              │ Review/edit screen        │
                                                              │ (user always sees this     │
                                                              │  before anything saves)    │
                                                              └───────────┬───────────────┘
                                                                          │ confirmed
                                                                          ▼
                                          ┌───────────────────────────────────────────────┐
                                          │ SLM (Qwen3-4B, loaded HERE, unloaded after)      │
                                          │  → DifficultyTier (closed enum)                  │
                                          │  → optional TaskDecomposer (≤4 subtasks, capped) │
                                          └───────────────────┬───────────────────────────────┘
                                                               │ SubtaskSpec[] + tier
                                                               ▼
                                          ┌───────────────────────────────────────────────┐
                                          │ Tool-call chips: SET_REMINDER / SET_ALARM /      │
                                          │ START_TIMER / ADD_TODO — one tap each to confirm │
                                          └───────────────────┬───────────────────────────────┘
                                                               │ on completion
                                                               ▼
                                          ┌───────────────────────────────────────────────┐
                                          │ GamificationEngine: tier → XP (deterministic     │
                                          │ mapping, non-losable, completion-only — §4.7)   │
                                          └───────────────────────────────────────────────────┘
```

**Only two models are ever loaded, and never concurrently:** PP-OCR loads for the capture step and
unloads; Qwen3-4B loads for scoring/decomposition and unloads. EmbeddingGemma (notes search) loads
only if GoalContext's note lookup is actually invoked for the explanation step (§4). This is the
2.2 sequential-loading rule from PIVOT_PLAN.md — the architecture enforces it structurally, it isn't
just a testing goal anymore.

---

## 4. Overload detection's real place: one decision point among four

```
UnlockTracker / AppSwitchTracker / NotifLatencyTracker (background, always running — cheap, no model)
                    │
                    ▼
      BaselineStore (Welford z-scores) ── OverloadClassifier ── Orchestrator
                    │
                    ▼
      Decision point C (§2) — fires into the SAME decision-rule layer as capture completion
      and due-soon todos. It does NOT get its own separate pipeline or separate demo beat.
                    │
                    ▼
      InterventionBandit picks: SHOW_OVERLAY (with SlmExplainer's one-sentence, GoalContext-
      grounded explanation) OR defers if cooldown/low severity — same bandit, same logging,
      same FeedbackLoop measurement as every other decision point.
```

This is the structural fix for the "why is detection different from a behavioral model" question:
it isn't different, and it isn't supposed to be the headline — it's one input decision point feeding
the same measured, closed-option, confirm-gated loop as everything else in §2.

---

## 5. What got simpler vs. the original plan

| Original | Pivot architecture |
|---|---|
| 5 on-device models, concurrency untested | 2 models (SLM, OCR) + 1 optional (embedder), never concurrent |
| Detection = separate hero pipeline | Detection = decision point C, same rule/logging layer as everything else |
| "Break into bite-sized tasks" (open-ended) | `TaskDecomposer` → capped, schema-validated `SubtaskSpec[]`, deterministic fallback |
| Gamification XP source unspecified | `DifficultyTier` closed enum → deterministic XP table (§2.3 of PIVOT_PLAN) |
| EdgeSAM + DocScanner required | Bounding-box crop for MVP; both are stretch-only |
| Calendar folded into core GoalContext | Untouched stretch module, nullable dependency already isolates it |

---

## 6. One-sentence summary

Four fixed decision points feed one shared decision-rule layer (deterministic code + masked model
calls only), which can only select from a closed set of interventions, every real-world write is
user-confirmed, and every outcome is logged back into the same bandit — that's the whole system, and
overload detection is exactly one of the four inputs, not a separate product.
