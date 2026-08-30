# Model placeholders

Every on-device model in ATARI sits behind an interface in
`lib/core/services/model_services.dart`. This directory holds the
deterministic, no-weights implementation of each one.

**Why:** the app is built model-free on purpose (Plans/PIVOT_PLAN.md §2.2, §2.5).
The whole product loop — capture → structured item → confirmed reminder → XP —
works end-to-end today, and each model can be dropped in later without touching
UI or engine code.

| Interface | Placeholder here | Real implementation (later) |
|---|---|---|
| `DifficultyScorer` | keyword + length heuristics | Qwen3-4B, constrained to the `DifficultyTier` enum |
| `TaskDecomposer` | splits on conjunctions the user already wrote | Qwen3-4B, JSON-schema constrained, capped at `maxSubtasks` |
| `SlmExplainer` | fixed one-sentence template per signal | Qwen3-4B, output validated per `native/model` contract |
| `OcrService` | canned schedule text | PP-OCRv5/6 over a platform channel |
| `NoteSearchService` | keyword overlap | EmbeddingGemma-300M cosine top-k |

## Rules these placeholders follow

1. **Never hallucinate content the user didn't provide.** `PlaceholderTaskDecomposer`
   splits text the user already wrote rather than inventing plausible steps — a
   placeholder that fabricates convincingly is worse than one that declines,
   because the user has to undo the result.
2. **Same failure shape as the real path.** Over-cap decomposition falls back
   instead of truncating; scoring falls back to `fallbackDifficultyTier` instead
   of throwing. Swapping in a real model must not change how callers handle
   failure.
3. **Always honest about being a placeholder.** Every implementation reports
   `ModelBackend.placeholder`, and the UI surfaces that badge — nothing in the
   app claims a model ran when one didn't.

## Swapping in a real model

Implement the interface, report `ModelBackend.onDevice`, and register it in
`lib/core/services/service_locator.dart`. Nothing else changes: no UI edits, no
engine edits, no changes to any caller.

Per §2.2, load **one heavy model at a time** — load, infer, unload — rather than
keeping several resident. Model file paths are configured through
`SlmModelConfigService` (`atari.dev/slm` platform channel); the settings screen
exposes that path field already.
