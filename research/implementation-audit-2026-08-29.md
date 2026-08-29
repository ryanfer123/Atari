# Backend-native implementation audit — 2026-08-29

Branch audited: `feat/backend-native`

Device: iQOO 15 (`I2501`), Android 16 / API 36

## Executive result

The pasted completion summary was not accurate enough to use as a release record. The privacy boundary,
basic sensing bridge, baseline statistics, TTS bridge, Flutter debug harness, and test suites are real.
The ATARI app does not yet contain a connected language-model runtime, EdgeSAM, DocScanner, or PP-OCR.
The earlier model and OCR demonstrations were deterministic placeholders presented as real output.

This audit removes those false-positive states, packages the native validation contract, proves Qwen3-4B
in a separate upstream llama.cpp harness on the physical phone, and fixes two sensing gaps. Remaining
model and vision work is explicitly marked pending in the installed UI.

## Claim-by-claim status

| Area | Verified status | Evidence / correction |
|---|---|---|
| No `INTERNET` permission | Pass | Source manifest and built APK permission dump contain no `android.permission.INTERNET`. WorkManager adds `ACCESS_NETWORK_STATE`, but that permission cannot open network sockets. |
| App-switch tracking | Pass after correction | `UsageStatsManager.queryEvents()` counts distinct `ACTIVITY_RESUMED` transitions. The initial foreground app is no longer miscounted as a switch. |
| Unlock tracking | Partial, corrected design | Timestamp persistence works. `USER_PRESENT` is now registered at runtime because it is not an Android 8+ manifest-broadcast exemption. A metadata-maintenance `WorkManager` job is registered at the platform minimum 15-minute interval. The physical phone had no showing keyguard, so a genuine system `USER_PRESENT` delivery could not be produced in this session. |
| Notification response latency | Pass for shared event path | Post-to-removal and post-to-next-unlock are both implemented, metadata-only, bounded, and persisted. Physical debug-path evidence recorded one unlock and resolved the active notification to a 144,216 ms latency. |
| Welford/Bayesian baseline | Pass for implemented scope | Dart tests pass. The implementation uses `(hour, weekday)` buckets: 24 × 7 = 168 buckets per signal, not the claimed 4 × 7 = 28. |
| Qwen/Gemma inside ATARI | Not implemented | ATARI packages `libatari_model_jni.so`, which is the bounded-output contract only. It has no llama.cpp model loader. `isModelReady` now correctly returns false and the dashboard labels output as deterministic fallback. |
| Qwen3-4B physical inference | Pass in isolated harness | Upstream llama.cpp loaded the exact 2,497,280,256-byte Q4_K_M GGUF and generated a valid one-sentence explanation. See `device-results/2026-08-29-iqoo-15-qwen3-4b-inference.json`. |
| Masked source selection | Partial | Allow-list validation and the three-source cap exist. ATARI currently uses a deterministic heuristic and returns `usedModel: false`; model-based selection is pending runtime integration. |
| Scribble crop | Prototype only | Bounding-box crop works for a valid local source bitmap. EdgeSAM segmentation and DocScanner dewarping are not connected. |
| PP-OCR | Not implemented | The previous fixed text and 88% confidence were hard-coded. They were removed; the bridge now returns empty OCR with `pipelineReady: false`. |
| Offline TTS | Pass | Android `TextToSpeech` bridge initializes, speaks, stops, reports lifecycle callbacks, and now applies bounded rate/pitch options. |
| Dashboard | Pass as debug harness | Physical UI runs and reports real sensing metadata. It is not the complete frontend specified in `frontend_prd.md`. Labels now distinguish fallbacks and pending pipelines. |
| Android 16 targeting | Pass after correction | Main app now compiles and targets API 36. The earlier API 35 configuration targeted Android 15 even though it ran on an Android 16 phone. |
| Native/Dart tests | Pass, with scope correction | Native model-contract test: 1/1. Dart tests: 23/23. Static analysis: zero issues. Platform-channel tests use mocked native replies and therefore do not prove JNI, OCR, TTS audio, or model execution. |
| End-to-end integration tests | Missing | No implemented `integration_test/` flow covers the final airplane-mode loop. |

## Physical-device evidence

- Exact audited ATARI APK installed after preserving the previous package data to
  `/private/tmp/atari-audit.ulet2T/com.atari-data-before-update.tar`.
- Installed ATARI loaded `libatari_model_jni.so` successfully; no `dlopen` failure occurred.
- WorkManager registered and executed `SensingMaintenanceWorker` successfully.
- Usage access and notification-listener access were enabled.
- Dashboard observed one persisted debug-path unlock and a persisted notification latency of 144,216 ms.
- UI evidence:
  - `/private/tmp/atari-audit.ulet2T/installed-dashboard-verified.png`
  - `/private/tmp/atari-audit.ulet2T/installed-dashboard-verified.xml`

## Model gate result

Qwen3-4B is runtime-compatible and produces acceptable bounded output, but it is not yet a safe
always-resident default. The two runs observed approximately 4.51–4.95 GiB RSS, substantial swap, and
6.0–29.5 second generation latency. Reducing context from 8192 to 1024 tokens cut the KV cache from
1152 MiB to 144 MiB, but did not make total process memory or latency stable enough to skip a smaller
model comparison.

## Ordered next work

1. Benchmark Gemma 3 1B QAT Q4_0 (or a comparable sub-1B candidate) with the identical prompt set,
   including time-to-first-token, token throughput, repeated-run percentiles, battery, and thermals.
2. Embed the winning llama.cpp runtime behind `SlmPlugin`; keep deterministic validation and fallback
   outside the model runtime.
3. Replace the crop prototype with the first real vision milestone: PP-OCR on a user-provided crop.
   Add EdgeSAM and camera-only dewarp only after flat OCR is measured.
4. Add Android tests for notification removal vs next-unlock first-wins behavior and persistence reload.
5. Build the engine workstream still missing from this branch: overload state machine, feedback loop,
   bandit, goal retrieval, captured-item parsing, and gamification engine.
6. Implement the product frontend and final airplane-mode integration test described by
   `Plans/IMPLEMENTATION.md`.
