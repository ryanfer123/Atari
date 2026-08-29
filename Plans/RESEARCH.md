# Research Brief — On-Device Overload Agent
**iQOO City Battles 2026 · Open Innovation track · 7-day window (30h city battle + prep)**

Ledger: `/tmp/claude-1000/-home-mahmood-Projects-iQOO/89d85140-bcad-4ae2-a9e0-1565c9856c06/scratchpad/ml-intern/on-device-overload-detection-agent.md` (78 rows across 7 clusters — phone-signal sensing, on-device SLMs, JITAI/nudge effectiveness, bandit personalization/low-N classifiers, on-device embedding models, personal RAG/goal-grounded assistants, context/calendar-aware interventions — plus Dotsin's verified papers; arXiv + HF Papers only, resumable). A second ledger covers the gamified capture-to-organize expansion (85 rows across 4 clusters — freeform selection + document rectification, on-device OCR/VLM document parsing, on-device image embedding models, gamification/habit-formation effectiveness + wellbeing tension) at `/tmp/claude-1000/-home-mahmood-Projects-iQOO/89d85140-bcad-4ae2-a9e0-1565c9856c06/scratchpad/ml-intern/gamified-capture-organize-layer.md`. A third ledger covers the flagship-hardware agentic upgrade (91 rows across 3 clusters — flagship-capable agentic/tool-calling models, small-model multi-step tool-orchestration reliability, concurrent multi-model serving on 16GB RAM) at `/tmp/claude-1000/-home-mahmood-Projects-iQOO/89d85140-bcad-4ae2-a9e0-1565c9856c06/scratchpad/ml-intern/flagship-agentic-upgrade.md`.

---

## Bottom line

Build a **rule-based** (not ML) overload classifier over three passively-collected signals — unlock frequency, notification response latency, app-switching rate — scored against a **personal, hour-of-day-bucketed baseline** (Welford online mean/variance), with a **Bayesian population-prior blend** for cold start so the app works from first launch instead of needing days of data. On overload, an on-device **Gemma 3 1B (Google's official QAT Q4_0 GGUF, ~1GB)** turns the structured signal snapshot into one plain-language sentence, spoken via on-device TTS and shown in a focus-layer overlay. A feedback loop logs each intervention as a **pre/post treatment-effect measurement** (not just a log entry) and a small epsilon-greedy bandit picks which intervention type to try next. Zero network permissions, demoable in airplane mode.

This is deliberately **Tier 1 (rule-based) as the shippable core**; a Tier 2 tiny classifier or LoRA-tuned SLM is a stretch goal, not the critical path — the literature search found nothing that beats a well-tuned rule-based baseline at this signal set and time budget, and one paper (arXiv:2510.14513) found its own rule-based baseline outperformed passive-logging-only.

Two ideas below come from Dotsin.ai (an AI lab building something adjacent, given to us as inspiration) and are the main source of **novelty** in this build — see "Dotsin.ai analysis" below for what's real vs. marketing there.

**The single strongest piece of evidence found in the whole survey:** Time2Stop (arXiv:2403.05584, N=71,
8-week field study) measured that adding *explanations* to an adaptive smartphone-overuse intervention
increased user receptivity by **+53.8%** and intervention accuracy-perceived-as-helpful by **+11.4%**
over the adaptive-timing model alone. That is exactly what the on-device SLM does in this build — it
is not a demo flourish, it is the single highest-leverage component for whether the intervention
actually gets accepted rather than dismissed. See "Decision justification" below for the full
evidence chain behind every other component.

---

## Core reading

1. **Unlocking Mental Health: Exploring College Students' Well-being through Smartphone Behaviors** — arXiv:2502.08766, Feb 2025
   What it does: 4-year longitudinal study using phone-unlock patterns to forecast mental-health status.
   Why it matters here: directly validates unlock frequency as a usable on-device feature; no code, but the signal choice is the point, not a model to reuse.
   Code: none.
   Caveat: no classifier accuracy reported in the abstract — treat as signal-selection evidence, not a benchmark to beat.

2. **Investigating the Effects of Mood & Usage Behaviour on Notification Response Time** — arXiv:2207.03405, Jul 2022
   What it does: regression model predicts notification response latency from mood + usage behavior (18 participants, 5 weeks).
   Why it matters here: the only source found that treats notification response latency as a state signal on its own — validates the third signal collector.
   Code: none.
   Caveat: paired with E4 wristband physiology in the original study; the phone-only slice is what we take.

3. **GLOBEM Dataset: Multi-Year Datasets for Longitudinal Human Behavior Modeling Generalization** — arXiv:2211.02733, Nov 2022
   What it does: open multi-year, multi-cohort benchmark testbed for behavior-signal generalization.
   Why it matters here: best available reference methodology for *how to evaluate* an idiographic (personal) baseline without a multi-year dataset of our own — borrow the evaluation framing, not the data.
   Code: github.com/uw-exp/globem (351★, last commit 2024-01).
   Caveat: full dataset is heavier than a 7-day build needs; use it as a design reference only.

4. **State Your Intention to Steer Your Attention: An AI Assistant for Intentional Digital Living** — arXiv:2510.14513, Oct 2025
   What it does: cloud-LLM assistant over screenshots/app-titles for intentional phone use (22 participants, 3 weeks).
   Why it matters here: their own rule-based intent-reminder baseline beat passive-logging-only — direct precedent that a lightweight rule-based approach is defensible against a fancier alternative, which is exactly the call this project makes.
   Code: github.com/IntentAssistant/INA (11★).
   Caveat: not otherwise reusable — architecture is cloud-LLM-over-screenshots, not on-device-feasible.

5. **google/gemma-3-1b-it-qat-q4_0-gguf** — Hugging Face, Google official
   What it is: Gemma 3 1B Instruct, quantization-aware-trained and released at Q4_0 GGUF, ~1GB.
   Why it matters here: best param-count/quality/quant fit found for a 1-3B on-device budget — QAT means the Q4 quant keeps near-bf16 quality instead of the extra degradation a post-training quant takes.
   Code: model repo only (no training code needed — this is inference-only usage).
   Caveat: 32K context (not the full 128K some Gemma 3 variants advertise) — irrelevant here since prompts are short structured snapshots, not long documents.

6. **PhoneLM: an Efficient and Capable Small Language Model Family through Principled Pre-training** — arXiv:2411.05046, Nov 2024
   What it does: fully open (weights + code + data) 0.5B/1.5B model family with an Android-oriented function-calling finetune.
   Why it matters here: useful evidence for phone-oriented small-model design and a possible fallback model family.
   Code: github.com/UbiquitousLearning/PhoneLM and its separate `mllm` runtime.
   Caveat: it is not a Gemma/llama.cpp Android harness. Use upstream `ggml-org/llama.cpp/examples/llama.android` for the selected GGUF runtime reference.

6a. **Official Android runtime references** — `ggml-org/llama.cpp` and `google-ai-edge/LiteRT-LM`
   What they provide: maintained Android model loading, generation, streaming, and benchmark paths; LiteRT-LM also exposes stable Kotlin/C++ APIs and accelerator backends.
   Why they matter here: these replace the earlier assumption that a PhoneLM application must be forked for Android inference plumbing.
   Decision: keep ATARI's explanation contract runtime-independent, benchmark both viable paths on the target iQOO device, and retain `llama.cpp` as the initial GGUF integration path.

7. **RadLite: Multi-Task LoRA Fine-Tuning of Small Language Models for CPU-Deployable Radiology AI** — arXiv:2605.00421, May 2026
   What it does: LoRA-tunes a small Qwen model (2.5-4B) to turn *structured findings* into report text, running CPU-only at 1.8-2.4GB, 4-8 tok/s.
   Why it matters here: closest architectural analog found to "structured signal snapshot → one sentence" — different domain (radiology), same pattern. If Tier 1 prompting of the base model isn't reliable enough, this is the template for a Tier 2 LoRA stretch goal (fine-tune on a few hundred synthetic structured-input → sentence pairs).
   Code: github.com/RadioX-Labs/RadLite.
   Caveat: domain mismatch means don't reuse weights, only the recipe.

8. **Time2Stop: Adaptive and Explainable Human-AI Loop for Smartphone Overuse Intervention** — arXiv:2403.05584, Mar 2024
   What it does: 8-week field experiment (N=71) on adaptive-timing smartphone-overuse interventions, with an ablation isolating the effect of adding explanations.
   Why it matters here: direct quantitative evidence that explanations are not cosmetic — they measurably increase intervention receptivity (+53.8%) and perceived helpfulness (+11.4%) over the adaptive model alone. This is the evidence base for making the SLM's one-sentence explanation the centerpiece, not a stretch feature. Also the best available anchor for a *realistic* target behavior-change number: app-visit frequency dropped 7.0-8.9%, not a dramatic swing.
   Code: none found.
   Caveat: their adaptive-timing model is more complex than this project's static-threshold trigger — the explanation-effect finding is what transfers, not the full architecture.

9. **Fully Autonomous Z-Score-Based TinyML Anomaly Detection on Resource-Constrained MCUs Using Power Side-Channel Data** — arXiv:2604.08581, Mar 2026
   What it does: a rule-based z-score anomaly detector trained on just 14 days of baseline data, running on-device in 3.3KB SRAM / 63KB Flash with microsecond latency.
   Why it matters here: the closest empirical (not just theoretical) proof that a Welford/z-score rule-based detector reaches strong performance (precision=1.00, recall=1.00 in their case) at the exact data scale this project has (~1-2 weeks of personal baseline) — direct validation of the Tier 1 architecture choice.
   Code: none found.
   Caveat: single-device household power-monitoring case study, not phone behavioral data — the transfer is "this class of method works at this data scale," not the specific thresholds.

10. **Revisiting Discriminative vs. Generative Classifiers: Theory and Implications** — arXiv:2302.02334, Feb 2023
    What it does: theoretical + empirical comparison showing generative/rule-like classifiers reach near-asymptotic error with O(log n) samples, versus O(n) for discriminative/trained classifiers — generative wins consistently in the low-data regime.
    Why it matters here: the theoretical backing for why "rule-based over trained ML" isn't just a time-budget shortcut but the statistically correct choice at n≈1 week of personal data. See "Decision justification" below.
    Code: none found (pretrained-vision-feature experiments, not behavioral data — theory is domain-general, the experiments aren't).
    Caveat: their experiments are on vision features, not behavioral time series — the O(log n) vs O(n) result is a general statistical-learning-theory claim, not something re-validated on phone-usage data specifically.

---

## Also relevant

- **PULSE** (arXiv:2605.17679, May 2026) — LLM-agent compares current smartphone sensing to a personal baseline for affective intervention timing (balanced acc 0.71-0.74). Confirms "compare to personal baseline" as a viable framing; architecture is cloud-agent-heavy, not reusable directly.
- **Learning Behavioral Signals from Encrypted Smartphone Network Traffic** (arXiv:2605.01616, May 2026) — finding that *stress tracks persistent between-person variation while loneliness tracks within-person fluctuation* is a useful modeling caution: don't build one baseline model for "overload" in general, keep signal-specific baselines.
- **MobileQuant** (arXiv:2408.13933, Aug 2024) — PTQ method cutting mobile-NPU latency/energy 20-50%; relevant if Gemma 3 1B GGUF is too slow on the loaner phone's Snapdragon and a re-quantization pass is needed.
- **Large Models for Small Devices** survey (arXiv:2608.15693, Aug 2026) — concrete quant-accuracy datapoint (Qwen3.5 0.8B, 93.85 F1 at Q5_K_M) and a warning that **pruning breaks GGUF k-quant alignment** (up to 3.4x latency regression) — stick to quantization only, never pruning, for the SLM.
- **SHAKTI** (HF Papers, 2410.11331, Oct 2024) — 2.5B edge-optimized SLM, in-budget alternative to Gemma 3 1B if Gemma's license or context handling becomes a blocker.
- **Qwen2.5-0.5B-Instruct-GGUF** — smallest-footprint fallback if the loaner device turns out to be lower-end than expected.
- **InteractOut** (arXiv:2401.16668, Jan 2024) — friction/input-manipulation beats timed lockout by an *extra* 15.6% usage-time cut, 16.5% fewer opens, 25.3% higher acceptance (N=42, 5wk). Suggests a possible 4th bandit arm (a short confirmation delay before dismissing the focus layer) — see §7 stretch goals in IMPLEMENTATION.md.
- **MindShift** (arXiv:2309.16639, Sep 2023) — LLM-generated interventions, N=25, 5wk: acceptance +4.7 to +22.5pp, usage duration −7.4 to −9.8% vs. baseline nudges. Another realistic-effect-size anchor, same order of magnitude as Time2Stop.
- **HeartSteps** (arXiv:2501.02137, arXiv:1909.03539) — establishes real-world JITAI cadence: ~1.5 interventions/day, 5 decision points/day per user. Used to size the bandit's expected trial count — see "Decision justification."
- **Before You Scroll Again** (arXiv:2606.08965, Jun 2026) — finds the gap between *intended* and *actual* use predicts "regretful" sessions far better than raw duration (duration's predictive power collapses once intent is modeled). A genuinely novel stretch idea: capture a lightweight intent signal per app-open rather than relying on duration/frequency alone. Needs a wearable in the source study; the phone-only analog (inferring intended-vs-actual from historical per-app session-length distribution) is untested but promising — flagged as a Tier 2 novelty stretch, not core.
- **Excessive Screen Time...Mental Health Problems and ADHD** (arXiv:2508.10062, Aug 2025, N=50,231) — correlational epidemiology (anxiety aOR=1.45, depression aOR=1.65, ADHD aOR=1.21 at ≥4hr/day screen time). Useful only as pitch-deck motivation, not an intervention effect size — don't cite it as evidence the intervention works, it isn't that kind of study.
- **Protégé-effect digital-stress teaching intervention** (arXiv:2510.12944, Oct 2025, N=137, 3wk, 4 arms) — **null result**: no significant between-group difference. Included deliberately as a caution — not every plausible intervention design works, and the feedback loop must treat a null effect from one of its own bandit arms as valid signal, not a bug (see IMPLEMENTATION.md §4.4).

## Coverage gaps (report these, don't paper over them)

- **No paper benchmarks tokens/sec on an actual Snapdragon SoC.** The only smartphone-inference-speed paper found (arXiv:2312.12472) is iPhone/Apple-silicon only. This means device-level latency testing on the actual loaner phone during Green Light is not optional — budget real time for it on day 1-2, don't assume the numbers from any paper transfer.
- **"App-switching frequency" and "screen-time fragmentation" as named constructs are essentially unstudied** in arXiv/HF literature — every recent hit uses unlock counts or notification latency, not switch-rate or fragmentation directly. This is a genuine gap the project fills, but also means there's no published threshold or feature-engineering recipe to copy — expect to hand-tune this one signal empirically against your own usage during the build.
- **Nothing found combines structured behavioral/sensor JSON input with single-sentence natural-language output** as its own studied task — RadLite (radiology) is the nearest analog, at one remove. Prompt-engineering the explanation sentence will need first-party iteration, not literature lookup.
- Several arXiv queries hit rate-limiting (HTTP 429) mid-survey; if resuming this ledger later, re-run `"phone usage" AND "stress"` and `"smartphone sensing" AND "stress"`, which did not complete.
- **No paper directly measures a "muted UI / reduced app set" focus-layer intervention against a control, with a clean effect size.** Every JITAI-effectiveness number found (Time2Stop, InteractOut, MindShift) is for friction- or timing-based interventions, not UI-simplification/muting specifically. The 7-16% effect-size range above is the best available proxy, not a direct measurement of this project's exact intervention design — treat the feedback loop's own logged data as the first real measurement of this specific mechanism.
- **No direct epsilon-greedy vs. UCB vs. Thompson sampling sample-efficiency comparison at low trial counts (~5-25) was found** — see "Decision justification" above for how this gap was handled.
- **Hugging Face Papers API returned essentially no relevant hits for HCI/behavior-change intervention queries** (dominated by unrelated GUI-agent/RL papers) — for this sub-domain, arXiv was the only useful venue of the two. Worth knowing before spending further search budget on HF Papers for similar HCI questions.

---

## Decision justification (numbers + logic, no unsupported claims)

Every major architectural choice in this build, with what actually backs it — statistics where the
literature has them, explicit logical reasoning where it doesn't. Where a claim is general statistical
theory rather than a specific arXiv/HF finding, that's labeled, not blended in as if it were a citation.

**Rule-based (Tier 1) classifier over a trained ML classifier.**
Two independent supports, one theoretical and one empirical, both pointing the same direction at this
project's data scale (~1 week of personal baseline):
- *Theory:* arXiv:2302.02334 shows generative/rule-like classifiers reach near-asymptotic error with
  **O(log n)** samples, versus **O(n)** for discriminative/trained classifiers — the crossover favors
  rule-based approaches specifically in the low-n regime this project is in.
- *Empirical analog:* arXiv:2604.08581's z-score rule-based detector, trained on **14 days** of
  baseline (same order of magnitude as this project's prep window), hit **precision=1.00, recall=1.00**
  on-device in 3.3KB SRAM — direct proof the method class works at this exact data scale, even though
  the domain (power side-channel, not phone usage) differs.
- *Logic on top of both:* a trained classifier also needs labeled "overloaded" ground truth, which
  doesn't exist for this project — a rule-based system needs none, only the baseline statistics
  themselves. This isn't a time-budget shortcut, it's the correct call independent of the deadline.

**Welford online mean/variance, bucketed by hour-of-day × day-of-week.**
Logic, not literature (this is a standard numerical-methods choice, not a research claim): Welford's
algorithm computes running mean/variance in O(1) time and memory per update with no numerical
instability from naive sum-of-squares accumulation — the only property that matters for a background
service running continuously on battery. Bucketing by time-of-day is the phone-only substitute for
Dotsin's "regime shift" framing (see below) — it needs no additional literature support beyond the
signal-choice papers already cited (arXiv:2502.08766, arXiv:2207.03405), since it's a preprocessing
choice on top of already-validated signals, not a new claim about behavior.

**Bayesian population-prior blend for cold start (Ĝ_t = w(t)·prior + (1−w(t))·empirical).**
Logic, not literature (general statistical theory — empirical-Bayes/shrinkage estimation, not a
project-specific finding): with fewer than ~20 personal observations in a given hour-of-day bucket,
a pure sample mean has high variance; blending it with a population-default prior is a standard
bias-variance tradeoff that provably reduces expected error versus using either the prior alone or the
sample mean alone at small n. The specific decay formula is adapted from Dotsin's paper 3
(arXiv:2606.13556) — see Dotsin section below for why that paper's own genomic application doesn't
transfer, but its math does.

**On-device SLM: Gemma 3 1B, Google's QAT Q4_0 GGUF.**
Numbers, not just vibes: 1GB file size, 32K context (irrelevant here — prompts are short), trained on
2T tokens, and on the benchmarks the model card actually reports: HellaSwag 62.3 (10-shot), BoolQ 63.2,
PIQA 73.8, ARC-e 73.0 (0-shot). **Caveat, stated plainly:** the model card does *not* publish a
perplexity or quality-retention delta between the QAT-Q4_0 version and full bf16 — Google's own claim
is qualitative ("preserve similar quality... while significantly reducing memory"), not a number. The
comparative logic for choosing QAT over the alternative PTQ release (`ggml-org/gemma-3-1b-it-GGUF`)
is architectural, not a measured delta: quantization-aware training bakes quantization into the
training loop rather than applying it post-hoc, which is documented practice for reducing quantization
loss, but this project did not independently verify the magnitude of that reduction for this specific
model. If Day 1's device testing (IMPLEMENTATION.md §3) shows unacceptable latency, arXiv:2408.13933
(MobileQuant) documents 20-50% latency/energy reduction from mobile-NPU-targeted requantization as a
concrete fallback lever, not just "try something else."

**Epsilon-greedy bandit over UCB/Thompson sampling for intervention selection.**
Mostly logic, partially numbers, with an honest gap: HeartSteps (arXiv:2501.02137, arXiv:1909.03539)
establishes real-world JITAI cadence at **~1.5 interventions/day, 5 decision points/day per user** —
over a build-and-demo window of roughly a week, that's on the order of **5-25 total trials per user**,
before any UCB confidence bound or Thompson posterior has enough data to meaningfully outperform
epsilon-greedy's flat exploration rate. **This survey did not find a direct epsilon-greedy vs.
UCB vs. Thompson sampling sample-efficiency comparison at this specific trial-count range** —
arXiv:2311.14359 (Thompson sampling, Drink-Less study) and arXiv:2312.06403 (RoME) both build more
sophisticated mHealth bandits and claim improvement over simpler baselines, but neither publishes the
trial count at which that improvement appears. The choice here is therefore: at an expected ~5-25
trials, the added implementation complexity and failure surface of UCB/Thompson sampling is not
justified by evidence that isn't there — simplicity wins by default, not by a proven margin. If this
assumption turns out wrong (more trials happen than expected), upgrading to Thompson sampling later is
a contained change (swap the `choose()` method in §4.4), not a rearchitecture.

**Realistic success threshold for the feedback loop: flag ≥5% signal reduction as "worked," not a
dramatic swing.**
Numbers: Time2Stop (app-visit frequency −7.0 to −8.9%), InteractOut (extra −15.6% usage time,
−16.5% opens vs. timed lockout), MindShift (−7.4 to −9.8% usage duration), and the heat/noise JITAI
comparator (behavior uptake only +2-17%) all converge on the same order of magnitude: **real JITAI
effect sizes are single-digit-to-teens percent, not 50%+ drops.** Setting the bandit's "did this
intervention work" threshold too high (expecting a dramatic before/after) would make every arm look
like it's failing, including ones that are genuinely working by the standard the literature itself
uses. This also matters for the demo pitch: claiming a huge measured effect from a few days of data
would be less credible to a technical jury than citing this literature-grounded, modest, honest range.

---

## Dotsin.ai analysis

Dotsin (the "AI lab" reference point) is building the **Large Behavioural-Omics Model (LBM)** — causal-reasoning foundation model over individual behavior, pitched with a "no PII ever leaves the device" privacy-first framing very close to this project's own pitch.

**What's real vs. marketing** (checked against arXiv + their HF/GitHub artifacts, not the homepage copy):

- **Real:** 3 of their 4 listed papers exist on arXiv — Correlation Is Not Enough (arXiv:2606.09672, Jun 2026), You Are in Control of Your State (arXiv:2605.27580, May 2026), Is It You or Your Environment? (arXiv:2606.13556, Jun 2026, self-labeled a *conceptual framework paper with no reported experiments*). Their one genuinely reproducible artifact is `Dotsin/lbm-benchmarking-embeddingsFT` on Hugging Face — three real 110M-parameter BERT-base embedding models, Apache-2.0, backed by a working GitHub repo (11 commits, runnable scripts). Its BIOSSES ρ=0.828 number matches the arXiv:2606.09672 abstract.
- **Not real / unverifiable:** the 4th listed paper title does not exist on arXiv under any search variant — likely SSRN-only, not peer-reviewed. Headline homepage numbers ("500B parameters," "200K+ users," "99.6% vs 57% personalization accuracy," "90% bias reduction") appear nowhere in any paper and the 500B-parameter claim directly contradicts their only real model (110M params). No named team or academic affiliation is disclosed; the legal entity is "One Oath Educational Research and Technologies Pvt Ltd," Bangalore.
- **Verdict:** one small, real, reproducible embedding-model contribution wrapped in a much larger unsubstantiated marketing narrative. Useful for concepts and framing, not for numbers or claims to cite.

**Concepts worth borrowing (Dotsin idea → hackathon-scale translation):**

1. *Regime-shift "digital twin"* → per-user online baseline bucketed by (hour-of-day, day-of-week), using Welford's online mean/variance. Flag a "regime" when the current window's z-score crosses threshold. No twin, no multi-modal fusion — just a bucketed running statistic.
2. *Causal state intervention* → **the UI intervention is the causal experiment.** Every time the focus layer fires, log the signal state before and after as a within-subject pre/post comparison — a real (if small-n) treatment-effect estimate, not a correlation. This is the mechanism behind "checks if it worked and adjusts itself" in the original brief, made concrete.
3. *Bayesian genomic-anchor decay formula* (paper 3: Ĝ_t = w(t)·prior + (1−w(t))·empirical) → swap the genomic prior for a **generic population-default threshold**, decaying toward the user's own accumulated data. Solves the same cold-start problem with zero genomic data, and means the app is useful on first launch during a judged demo instead of needing days of collected baseline.
4. *"Correlation is not enough"* → the SLM's one-sentence explanation should be phrased **against the personal baseline bucket**, not raw counts: "your notification response is elevated versus your usual Tuesday-afternoon pattern," not "you unlocked your phone 40 times."
5. *"No PII ever leaves the device"* → unlike Dotsin's harder claims, this one is fully achievable in a 30-hour build (zero `INTERNET` permission declared at all, on-device SLM, local-only storage) — lean into it as the credible, judge-verifiable differentiator, since it can be checked live by opening app info.

**Traps to avoid copying** (out of scope at hackathon scale): genomic anchoring (needs GWAS/genotype data — paper 3 is conceptual-only anyway); formal causal-discovery graphs (needs large multi-user datasets + graph-learning infra — the pre/post intervention log above is the substitute); multi-week validation studies (use short within-session before/after windows instead); any cross-device aggregation, federated learning, or homomorphic encryption (single-device only); fine-tuning the embedding model or anything else from scratch (use off-the-shelf pretrained small models, don't chase Dotsin's training-time claims).

---

## Hackathon rubric fit

| Criterion | Weight | How this build addresses it |
|---|---|---|
| End product quality (jury) | 30% | Tier-1 rule-based core is the thing most likely to actually work end-to-end live — prioritize this over any stretch-goal ML |
| Novelty & impact (jury) | 20% | Regime-aware baseline + intervention-as-experiment + cold-start Bayesian blend (Dotsin-derived) + goal-grounded explanations (notes/todos/health targets, opt-in calendar) — a real personalization story, not a generic "screen time" app |
| HackTracker: on-device AI, voice, camera (device data) | 15% | On-device SLM is the core already; add on-device TTS to speak the explanation (voice touchpoint) — do **not** force camera use, it dilutes the privacy pitch and isn't needed to score well on this line |
| Technical depth (jury) | 15% | On-device signal collection (UsageStatsManager, NotificationListenerService), local SLM inference, closed-loop threshold adaptation — real architecture, not a wrapper around a cloud API |
| HackTracker: Office Kit usage (device data) | 10% | Genuinely pair and use Office Kit throughout the build (screen mirror for on-device debugging, file transfer for logs) — this is scored on real usage counts/duration, not a feature to fake |
| Demo & presentation (jury) | 10% | Airplane-mode live demo is the single strongest 3-5 minute pitch beat available — plan the demo script around it explicitly |

Track chosen: **Open Innovation** — "local or open-source model at the core" is the stack nudge across every track, and this project has no natural single-track home (not FinTech/Commerce, not classroom-facing Education, arguably HealthTech-adjacent but not clinical) — Open Innovation avoids forcing an ill-fitting narrative.

---

## Concrete improvements surfaced by this pass

Five changes worth making to the plan in IMPLEMENTATION.md, each traceable to a specific finding above:

1. **Promote the explanation from "nice feature" to the design's central bet.** Time2Stop's
   +53.8%/+11.4% receptivity numbers mean the SLM's prompt quality (few-shot examples, phrasing
   against the personal baseline bucket) deserves more of the prep-week time budget than
   IMPLEMENTATION.md's Day 1 currently allocates — it's plausibly the single highest-leverage lever
   in the whole system for whether the intervention gets accepted at all, not a secondary polish item.
2. **Recalibrate the feedback loop's "did it work" threshold to ≥5% signal reduction**, not a large
   swing — see "Decision justification" above. Implement this as a named constant, not a magic number,
   so it's visibly literature-grounded when demoed to a technical jury.
3. **Add a 4th bandit arm: light friction (e.g. a 3-second confirmation delay before dismissing the
   focus layer).** InteractOut found friction-based mechanisms beat timed lockout by an *additional*
   15.6-16.5% — cheap to build (a delay + confirm tap), and gives the bandit a third qualitatively
   different lever beyond "show UI" vs. "show notification." Stretch goal, added to
   IMPLEMENTATION.md §7.
4. **Design the feedback loop to treat a null result as valid signal, not a bug.** The Protégé-effect
   paper's null result (arXiv:2510.12944) is a reminder that some intervention arms may show no
   measurable effect for a given user — the bandit should down-weight that arm accordingly, and the
   demo narrative can honestly say "the system learned break-notifications weren't working for this
   user and shifted to the focus layer" rather than needing every arm to look like a win.
5. **Tier 2/tier 3 novelty candidate: intent-vs-actual-use gap as a signal**, from arXiv:2606.08965 —
   genuinely fresh (Jun 2026) and not obviously something other hackathon teams will have found. Only
   attempt after the core loop (IMPLEMENTATION.md Day 5 exit criterion) is solid; it needs UX design
   for capturing "intent" cheaply (e.g., inferring from historical per-app session-length distribution
   rather than asking the user directly, to avoid adding friction to every app open).

## Expansion: goal-context layer (notes, todos, health targets, calendar)

The original scope was overload detection + intervention. The extended scope grounds that
intervention in the user's actual goals: notes, to-do items, health targets, and calendar/schedule,
so the explanation can say "this is pulling you away from your 3pm study block" instead of a generic
sentence. This section covers what the literature supports here, what it explicitly does *not* solve,
and the resulting architecture — including the one hard constraint: **calendar access needs OAuth +
network, which conflicts with the existing "zero `INTERNET` permission, airplane-mode demo" pitch.**
Ledger: 30 new rows across 3 clusters (E: embedding models, F: personal RAG/goal-grounded assistants,
G: context/calendar-aware interventions + schedule extraction), same ledger file as before.

### The one design principle everything below follows

**Use embeddings only for free-text notes. Everything else (todos, health targets, calendar events)
is structured data — filter it directly, don't embed it.** This isn't a shortcut, it's the logically
correct call: a todo has an explicit deadline field, a calendar event has an explicit time range, a
health target has an explicit metric and threshold — a `WHERE` clause on those fields is both cheaper
and more reliable than semantic search over the same content. Embeddings solve retrieval over
*unstructured* text, which only the notes actually are. Building a vector index for structured records
would be ML infrastructure solving a problem a database query already solves.

### On-device embedding model for notes: EmbeddingGemma-300M

**EmbeddingGemma-300M** (arXiv:2509.20354, Sep 2025) is SOTA among open embedding models under 500M
params on MTEB, ships as GGUF (`ggml-org/embeddinggemma-300M-GGUF`) and quantized ONNX
(`onnx-community/embeddinggemma-300m-ONNX`, q4 variant), and — critically — has a *verified on-device
Android deployment*: MAM-AI (arXiv:2606.29580, Jun 2026) runs it as the retriever in a fully offline
on-device medical RAG system on commodity Android hardware, where it ranks 3rd of 7 retrievers
overall and rivals cloud embedding systems. This is the same evidence bar the rest of this project's
stack was held to (RESEARCH.md core reading) — a model that's not just benchmarked, but shown running
on the target platform.

**Do not extract embeddings from the already-chosen Gemma 3 1B generator instead of using a dedicated
embedder.** LLM2Vec-Gen (arXiv:2603.10913, Mar 2026) shows generative-LLM hidden-state embeddings only
become competitive (+8.8% over an unsupervised teacher) *after* adding trainable tokens and a training
pass — naive zero-shot hidden-state pooling from an off-the-shelf model is not competitive. Running two
small models (Gemma 3 1B generator + EmbeddingGemma 300M retriever, ~1.3GB combined) costs more RAM
than one, but is the evidence-backed choice over trying to make one model do both jobs badly.

**RAM fallback if 1.3GB combined proves too heavy on the loaner device:** Snowflake Arctic-Embed-XS
(HF, 22.5M params) scores MTEB Retrieval NDCG@10=50.15, actually *beating* the more common
all-MiniLM-L6-v2 (same 22M param class, NDCG@10=41.95) — a ~13x smaller fallback than EmbeddingGemma
that's still a quality upgrade over the "everyone uses this" default, if Day 1 device testing shows
memory pressure.

### Cross-source fusion is a genuinely unsolved problem — scope down accordingly

This is the most important finding in this section, and it argues for *less* ambition, not more:
- **Setoka** (arXiv:2607.27056, Jul 2026), a benchmark for personalized agents over heterogeneous
  data, finds that systems handle semantic-memory retrieval (notes-style) fine, but accuracy degrades
  sharply on episodic memory, and degrades *further* on behavior/personality tasks requiring
  cross-source fusion — the closest available proxy for "notes + tasks + habits combined."
- **Claw-Anything** (arXiv:2605.26086, May 2026) benchmarks frontier cloud models (GPT-5.5-class) on
  multi-source personal-assistant tasks with noisy/conflicting events across activity history, backend
  services, and cross-device data — even at that scale, pass@1 is only **34.5%**.
- If state-of-the-art frontier models fusing multiple personal-data sources top out around a third
  correct, a 1B on-device model in a hackathon build attempting the same open-ended fusion will fail
  worse, not better. **Conclusion: don't build cross-source reasoning.** Keep each data type in its own
  structured store, retrieve from each independently (embedding search for notes, direct field filters
  for everything else), and combine them only as a flat list of short context bullets concatenated into
  the SLM's prompt at generation time — never as a joint embedding space or a single fused query.
- **PEARL** (arXiv:2601.11957, Jan 2026) supports this directly: a baseline scheduling agent (Qwen-3-30B)
  has a 35% average error rate; adding an *explicit, structured* preference-memory store (not implicit
  fused retrieval) cuts that error by 55% relative (~35% → ~16%). Explicit structure beats implicit
  fusion — this is the same principle as the design rule above, now with a number behind it.

### Context-aware timing: plausible, thematically supported, not numerically proven here

SigmaScheduling (arXiv:2507.10798, Jul 2025, N=68, 10wk) shows dynamic/context-informed decision-point
scheduling raises P(decision point precedes the target behavior) to **≥70%**, versus a fixed-interval
baseline that performs poorly for irregular routines — general support for "schedule-aware triggering
beats fixed-interval," though the study is about habitual behaviors (toothbrushing), not calendar
events specifically. "Before You Scroll Again" (arXiv:2606.08965, already cited in Core Reading) adds
that the gap between *intended* and *actual* use predicts regret far better than raw duration — the
same logic extends naturally to "a todo says 'study 2hrs' and you opened Instagram mid-block" being a
more meaningful overload signal than raw switch-count alone.

**Be honest about the gap:** the single closest study, "Fitting the Message to the Moment"
(arXiv:2505.23997, May 2025), tests calendar-aware LLM stress messaging directly — but it's
qualitative-only (N=8, one week), and found users valued the *relevance and trust* of calendar-aware
messages thematically, without a quantitative effect size versus a calendar-blind baseline. **No paper
in this survey directly measures calendar-aware vs. calendar-blind intervention effectiveness with a
number.** Treat "grounding in goals improves outcomes" as this project's own hypothesis to demonstrate,
not a proven literature claim — say so plainly in the pitch rather than overclaiming.

### Calendar OAuth vs. the privacy pitch — pure logic, no literature (and here's why)

This survey found **no arXiv/HF paper on mobile permission-grant psychology, install-rate impact of
sensitive permissions, or calendar-OAuth privacy tradeoffs specifically** — that's CHI/SOUPS/USENIX
Security literature, outside this skill's arXiv+HF-Papers scope. The two nearest proxies found
(arXiv:2508.19493 "Mind the Third Eye," privacy-awareness in AI agents acting *on* the phone, best
model only 67% privacy-aware; arXiv:2604.00986 "Do Phone-Use Agents Respect Your Privacy?," agents
over-fill optional personal fields) are about AI agents leaking context, not about human trust in
granting a permission — not the same question, don't force-fit them as evidence.

The resolution here is architectural logic, stated as such:
1. **The core loop stays exactly as designed — zero `INTERNET` permission, fully airplane-mode
   demoable.** Signal collection, classifier, SLM explanation, focus overlay, and feedback loop never
   touch the network. This claim remains judge-verifiable in Settings exactly as before.
2. **Notes, todos, and health targets need no network or auth at all** — they're local user input
   (typed or uploaded), stored in Room. These fold into the "everything offline" story with zero
   compromise, exactly matching how the user themselves framed this ("just calendars is an auth API,
   but rest we can combine into embeddings").
3. **Calendar sync is a separate, explicitly opt-in module** with its own permission grant screen
   ("Connect calendar — optional"), requested only if the user chooses it, never bundled into the
   base install. The app must be fully functional and demoable without it.
4. **This turns a scope conflict into a demo strength, not a weakness:** show the airplane-mode core
   loop first (with notes/todos providing goal-context, no network), then — separately, network back
   on — show "Connect calendar" as an additive layer, narrating explicitly: "everything you just saw
   works fully offline; calendar sync is opt-in and only adds context, it's never required." A judge
   watching graceful degradation is stronger evidence of technical depth than a feature that silently
   requires network the whole time.

### Schedule/timetable upload (image or PDF) — feasible on-device, but MVP should skip it

**DocSLM** (arXiv:2511.11313, Nov 2025) is a small vision-language model for long multimodal document
understanding that matches/surpasses SOTA while using 82% fewer visual tokens, 75% fewer parameters,
and 71% lower latency — edge-deployable in principle. **Caveats, stated plainly:** it's evaluated on
general long-document benchmarks, not timetable/schedule layouts specifically; the GitHub repo
(github.com/Tanveer81/DocSLM) has only 6 stars and no confirmed phone deployment. This is a real,
recent (Nov 2025), on-device-feasible candidate for parsing an uploaded class/work schedule
photo — but unverified for this exact use case. **MVP should use manual structured entry** (a simple
recurring-schedule-block form) with DocSLM-based image parsing as a Tier 3+ stretch goal, not core —
consistent with the project's existing MVP-first pattern.

### One more borrowable pattern: narrate structured data through the SLM, not just overload signals

AWARE Narrator (arXiv:2411.04691, Nov 2024) converts raw smartphone sensor streams into LLM-readable
narrative summaries for downstream analysis — the same pattern this project already uses for overload
signals (§4.3 in IMPLEMENTATION.md). The extension: the same SLM call that explains "why you're
overloaded" can also incorporate the retrieved goal-context bullets (today's todos, relevant note,
current calendar block) in one prompt, rather than building a second explanation pipeline — reuse the
existing SlmExplainer, just richer input, not a new component.

### What's explicitly out of scope, even as a stretch goal

- **Personal knowledge graphs** (arXiv:2605.18763 shows ~70% win rate over standard RAG for
  personalized wearable-data queries via a global+local-deviation graph) — a genuinely better retrieval
  architecture than flat embeddings, but graph construction/maintenance is more engineering than a
  7-day build affords. Note it as a real post-hackathon direction, not something to attempt now.
- **RL-trained personal agents** (PEARL's own architecture, beyond borrowing its preference-memory
  finding) — training infrastructure is out of budget entirely.
- **Any fine-tuning of the embedding or generator model on personal data** — zero-shot/prompted use of
  off-the-shelf models only, consistent with the rest of the project's approach.

---

## Expansion: gamified capture-to-organize layer

Two more additions on top of the goal-context layer above: a **freeform, Google-Lens-style capture
flow** (the user draws a loose shape over a photographed page or on-screen content, the app turns that
into a clean crop and extracts structured items), and a **gamification layer** (XP, levels, quests,
streaks, achievements) combining "addictiveness" with organization — Habitica-style engagement applied
to the app's existing todo/note/health-target model. This section covers what the literature actually
supports for each, and is deliberately blunt about the one place it argues *against* the direction
asked for: gamification sits in real tension with this app's own anti-overload mission, and the
literature does not resolve that tension cleanly. Ledger: 85 rows across 4 clusters (A: freeform
selection + document rectification, B: on-device OCR/VLM document parsing, C: on-device image embedding
models, D: gamification/habit-formation effectiveness + wellbeing tension), same ledger location
pattern as before.

### Freeform capture: no single paper solves "circle it, get a clean image" — compose two models

Nothing in the survey does loose-scribble-to-clean-crop as one studied task. The closest matches are
interactive-segmentation models (scribble/click prompts to a mask) and, separately, document
rectification models (perspective correction for a photographed page) — the pipeline has to compose
one of each:

- **EdgeSAM** (arXiv:2312.06660, Dec 2023) distills SAM's ViT encoder into a purely CNN-based
  architecture explicitly optimized for edge devices — the most concretely edge-targeted, released-code
  (github.com/chongzhou96/EdgeSAM) option for turning a loose scribble/click into a clean mask.
  **SqueezeSAM** (arXiv:2312.06736, Dec 2023, Meta Reality Labs) is the closest match to the *exact*
  product scenario — a mobile interactive-segmentation model built specifically for a phone camera app
  taking arbitrary loose user input — but has no released weights found, so it's a design reference, not
  a drop-in model. TinySAM, RepViT-SAM, and EfficientSAM are viable alternates in the same family if
  EdgeSAM's accuracy/speed tradeoff doesn't fit after Day-1-of-this-workstream testing.
- **DocScanner** (arXiv:2110.14968, Oct 2021, code released) rectifies a photographed page via
  progressive, iterative refinement of a shared lightweight module rather than one-shot regression — the
  best-fit dewarping stage for a photographed whiteboard/notebook page at an angle. This step only
  applies to camera-photo captures; a pure in-app screenshot region is already flat and skips it
  entirely.
- **No paper reports real Android NPU latency for any of these** — every "mobile" SAM variant benchmarks
  FLOPs/GPU timing, not measured on-device ms-latency, and the same is true of every rectification
  network found. This is the same coverage gap the project already carries for the SLM (RESEARCH.md
  "Coverage gaps" above) — treat it as confirmation of a project-wide pattern, not a new surprise: every
  on-device model choice here needs first-party latency verification before it's trusted, not just the
  language model.

### OCR / structured extraction: classical OCR wins on deployability, VLM wins on layout understanding

- **PP-OCRv5** (arXiv:2603.24373, Mar 2026, ~5M params) and **PP-OCRv6** (arXiv:2606.13108, Jun 2026,
  1.5-34.5M params) are tiny, deployable, and the right MVP pick for pulling raw text off a photographed
  schedule or list — both explicitly claim to rival billion-parameter VLMs on OCR tasks at a fraction of
  the size.
- **PaddleOCR-VL** (arXiv:2510.14528, Oct 2025, 0.9B params) is the upgrade path if flat OCR text loses
  too much of a timetable's row/column structure — a sub-1B document-parsing VLM, SOTA on OmniDocBench,
  purpose-built for tables/formulas/charts, not just running text.
- **Donut** (arXiv:2111.15664, Nov 2021) is a useful architectural reference, not the pick: an
  OCR-free end-to-end model (reads the image directly, no separate OCR engine) proving the pattern works
  in principle, but it's 2021-era with no updated on-device numbers.
- **E-ARMOR** (HF-2509.03615, Sep 2025) is the closest thing found to a direct, controlled comparison of
  classical edge-optimized OCR against several small/mid VLM-OCR approaches (GOT-OCR2.0, InternVL, Qwen-
  VL family, MiniCPM) under resource constraints — use it as the evaluation reference when doing
  Day-1-of-this-workstream testing, rather than trusting any single paper's self-reported numbers.

### Should captured images get their own embedding, or is OCR text + the existing pipeline enough?

Genuine disagreement in the literature, reported both ways rather than smoothed over:

- **For a dedicated image embedding:** Document Screenshot Embedding / DSE (arXiv:2406.11251, Jun 2024)
  found that embedding a document screenshot directly beats OCR-then-text-embed by 15+ nDCG points on
  slide retrieval and by 17 points top-1 accuracy vs. BM25 on text-intensive Wiki-SS — for text-and-
  layout-dense images (which schedules/whiteboards/timetables are), skipping OCR and embedding the image
  directly can meaningfully win. UniSE/Vis-IR (arXiv:2502.11431, Feb 2025) makes the same architectural
  argument: treat mixed text/image/table content as one unified "screenshot embedding."
- **Against (or "not needed"):** CIVIL (arXiv:2510.04010, Oct 2025), on personal first-person photo
  retrieval, found that generating a caption and embedding it with a text model — i.e., reusing exactly
  the kind of pipeline this project already has (EmbeddingGemma-300M over text) — works well, and is
  explicitly framed as the alternative to CLIP-style image embedding.
- Both DSE and CIVIL make their case with large/server-scale models, not mobile-sized ones — neither
  result guarantees a small on-device model reproduces the same gap in either direction. PhotoBench
  (arXiv:2603.01493, Mar 2026) adds a further caution: pure embedding models, image or text, "collapse"
  on personal-photo retrieval once non-visual context (time, place, social) matters — neither modality
  alone is a complete answer.
- **Resolution, stated as a judgment call, not a proven result:** the MVP does **not** add a dedicated
  image embedder. Captured images are OCR'd, and the OCR text goes into the existing EmbeddingGemma-300M
  notes pipeline (§ "Expansion: goal-context layer" above) exactly like a typed note. If testing shows
  OCR text is losing too much of a timetable's structure for retrieval to actually work,
  **MobileCLIP2** (arXiv:2508.20691, Aug 2025, Apple, 50-150M params, 3-15ms latency, best small
  on-device CLIP option found in the survey) is the concrete upgrade path — but only build it if the
  cheaper OCR+text-embedding path is measurably insufficient, not by default.

### Gamification: the literature does not resolve the tension with this app's own mission — treat that as a design constraint, not a feature to bolt on

This is the subsection that matters most, because the app's own stated boundary ("Gamification rewards
intentional action and recovery, not simply reduced screen time," per the project README) turns out to
need to be a hard rule, not a nice-to-have — the literature explains why:

- **Direct empirical link between gamified/persuasive design and addictive use.** "Do Persuasive Designs
  Make Smartphones More Addictive?" (arXiv:2106.02604, Jun 2021, N=183) found persuasive-design elements
  — which include reward/gamification mechanics — correlate with exactly the problematic-use patterns
  this app exists to reduce.
- **The same finding, sharper, on streaks specifically.** "AI-Driven Feedback Loops in Digital
  Technologies" (arXiv:2411.09706, Oct 2024, N=200) found streaks/badges/real-time feedback
  *simultaneously* help goal attainment **and** independently increase anxiety, autonomy-loss, and
  compulsive feedback-checking. This is not a clean win for gamification — it is a genuine, documented
  double edge, and the paper's own recommendation is to design feedback mechanisms that reduce cognitive
  load, not maximize engagement.
- **Manipulative design isn't fixable after the fact.** A Systematic Review of Dark Patterns
  (arXiv:2604.15323, Mar 2026) is the most rigorous single source here: manipulative UI patterns
  measurably change behavior (with large effect-size variance), and attempts to de-bias or counter dark
  patterns once they're in place mostly fail. "Ship it, then add a wellbeing disclaimer" is not a real
  mitigation by this evidence — the mechanic has to be designed correctly from the start.
- **The app's core mission doesn't actually need gamification to work.** MindShift (arXiv:2309.16639,
  already in Core Reading above) — a phone-overload-reduction agent in the same problem space as this
  app — gets real measured effect sizes (acceptance +4.7 to +22.5pp, usage duration −7.4 to −9.8%) from
  a *non-gamified*, context-aware persuasion approach. Gamification is being added here for engagement
  and hackathon-novelty reasons, not because the literature says the anti-overload mechanism requires
  it — keep that distinction explicit in the pitch rather than implying gamification is load-bearing for
  the core detection/intervention loop.
- **Concrete design rule this evidence supports** (logic, built on the findings above, not a citation of
  its own): reward *completion and effort* — a todo finished, a capture-to-organize action completed, an
  intervention the feedback loop's own pre/post measurement confirms worked (§4.7) — never reward raw
  reduced-screen-time or app-avoidance directly, and never use a streak that can be *lost* by a single
  missed day. "Unpacking Adherence and Engagement in Pervasive Health Games" (arXiv:2106.13747, Jun 2021)
  ties lasting adherence to Self-Determination Theory constructs (autonomy, relatedness) rather than
  reward mechanics themselves; "Designing for Engagement" (arXiv:2605.16276, Apr 2026) proposes exactly
  this SDT-over-raw-mechanics framework for digital health design. Concretely: levels/XP that only go up,
  and quests that can be re-attempted without penalty, instead of a fragile daily streak.
- **A realistic adherence number for the pitch, not an oversell.** The same health-games paper
  (arXiv:2106.13747) cites field retention of only 41% (single-player) / 29% (social) at 90 days even for
  well-designed gamified health apps — gamification measurably helps engagement, it does not "solve" it.
- **A concrete self-audit tool before shipping.** "Playing Games with My Heart" (arXiv:2605.08093, Apr
  2026) audits popular AI companion apps for manipulative-engagement dark patterns via a repeatable
  manual-annotation methodology. Before shipping the gamification layer, run the same style of self-audit
  against this app's own streak/XP/notification copy, using the taxonomy from "Dark Patterns at Scale"
  (arXiv:1907.07032) as the checklist — treat any mechanic that would fail that audit as a bug, not a
  feature. See IMPLEMENTATION.md §4.7 for where this lands as an actual pre-ship task.
- **Coverage note, stated honestly:** arXiv/HF indexes almost none of the core gamification/
  Self-Determination-Theory/streak-mechanics literature — it lives in ACM CHI/HCI proceedings, outside
  this skill's arXiv+HF-Papers scope. Several exact-phrase queries ("variable ratio reinforcement,"
  "streak mechanic behavior change," "gamification randomized controlled trial app") returned zero hits.
  The adherence-effect-size evidence above is real but drawn from adjacent domains (health games, social
  media, digital-stress interventions), not to-do/habit apps specifically — treat it as directional
  support, not a tight domain match.

---

## Expansion: flagship-hardware agentic upgrade

The actual demo/dev hardware is confirmed as an **iQOO flagship phone: 16GB RAM, Snapdragon-class
NPU, 512GB storage** — not the generic/unknown "loaner device" the original SLM budget (Gemma 3 1B)
was conservatively sized for. This section covers what changes given that headroom, what deliberately
does *not* change, and — because "agentic" is where this survey found the sharpest evidence against
the naive version of the idea — why the upgrade is scoped as **constrained, code-governed tool
selection**, not a free-form multi-step agent loop. Ledger: 91 rows across 3 clusters (flagship-capable
agentic/tool-calling models, small-model multi-step tool-orchestration reliability, concurrent
multi-model serving on 16GB RAM).

### What does *not* change, and why hardware doesn't affect it

- **The Tier 1 rule-based classifier stays rule-based.** That decision was justified by *labeled-data
  scarcity* — arXiv:2302.02334's O(log n) vs. O(n) sample-complexity result, at this project's ~1-week
  personal-baseline data scale — not by compute or memory limits. More RAM doesn't create more labeled
  "was I overloaded" ground truth. This argument is orthogonal to hardware and still holds.
- **Cross-source fusion is still out of scope.** Setoka and Claw-Anything (§Expansion: goal-context
  layer above) show even frontier cloud models fail at open-ended multi-source personal-data reasoning
  (34.5% pass@1) — a 4-8B on-device model is nowhere near frontier scale, so this conclusion doesn't
  soften with better hardware, it strengthens the case for staying disciplined about it.
- **The zero-`INTERNET`-permission core loop is unaffected.** The upgraded model and orchestration logic
  described below still run entirely on-device.

### Model choice: Qwen3-4B primary, Qwen3-8B as a measured upgrade, Gemma 3 4B as the GGUF-path alternate

- **Qwen3-4B is the primary pick.** It sits inside the size band "Are We There Yet?" (arXiv:2504.00002,
  a real-device measurement study) found actually runs successfully on mobile today — the same study
  found larger models "fail or are impractical" on-phone, a direct caution against defaulting to the
  top of the budget just because RAM allows it. Within that band, Qwen3-4B carries real evidence of
  agentic capability, not just chat quality: MidTool (arXiv:2608.20314) mid-trains Qwen3-4B specifically
  for tool-use and improves it on BFCL/tau2-Bench; ToolRM (HF-2510.26167) shows a 4B Qwen3 functioning
  as an effective function-calling *judge*, evidence of strong native tool-call understanding at this
  size; the speculator-RL paper (arXiv:2607.25816) lifts Qwen3-4B's tool-call Hit@1 from 44.1% to 61.2%
  with additional training.
- **Qwen3-8B is a measured upgrade path, not the default.** It has the single strongest accuracy number
  in the whole survey — UniToolCall (HF-2604.11557) fine-tunes Qwen3-8B to 93.0% tool-call precision,
  beating GPT/Gemini/Claude on that eval, and DIVE/Klear-AgentForge independently push Qwen3-8B to SOTA
  agentic-benchmark results — but no source validates an 8B model's *peak RAM* alongside the embedder
  and vision pipeline running concurrently (see "Concurrent serving" below), and it sits above the size
  band "Are We There Yet?" confirms as reliable on real phones today. **Only move to 8B if Day-1 device
  testing on the actual iQOO flagship shows real headroom** — treat this as a literal test, not an
  assumption, the same discipline the original 1B-vs-larger decision already used.
- **Gemma 3 4B/12B (arXiv:2503.19786, official technical report) is the alternate** if the Qwen3 GGUF/
  tool-calling integration path proves harder than Gemma's — the existing SLM harness (PhoneLM fork,
  llama.cpp JNI) is already built around Gemma-family GGUF loading, so staying in-family is lower
  integration risk. **Stated plainly: no arXiv/HF source in this survey confirms Gemma 3 4B/12B's
  function-calling benchmarks or a GGUF quantized release** — that data likely exists in Google's own
  model card/blog posts, outside this skill's arXiv+HF-Papers scope. Qwen3's technical report
  (arXiv:2505.09388) and quantization study (arXiv:2505.02214) are more thoroughly documented for this
  exact question, which is the deciding factor for the primary pick.
- **Honest coverage gap, stated as plainly as the original 1B latency gap was:** no paper in this survey
  benchmarks a 7B+ model's end-to-end chat/agent tokens-per-second on an actual **phone-class** Snapdragon
  8-Gen/Elite NPU. The closest real numbers are Transformer-Lite (arXiv:2403.20041, 6B-class ChatGLM2 on
  phone *GPU*, 14 tok/s decode — not NPU), mllm-NPU (arXiv:2407.05858, >1000 tok/s but *prefill only*,
  chipset not confirmed as Snapdragon), and the Snapdragon *X Elite* RAG paper (arXiv:2606.11257) — a
  laptop/PC NPU, not the phone Hexagon NPU this project actually targets. **This is the first real
  measurement question for Day 1 of the upgraded model's testing, exactly like the original Gemma 3 1B
  latency question was** — budget real device time for it, don't assume any of the above numbers
  transfer directly.

### Orchestration design: masked, code-governed tool selection — not a free-form multi-step agent loop

This is the most important finding in this section, and it argues for **less** open-endedness than
"agentic OS AI" might suggest, not more — the evidence against giving even a well-chosen on-device model
free multi-step tool orchestration is unusually consistent across sources:

- **Raw multi-step orchestration is weak at every scale tested, including frontier cloud models.**
  HyperTool (arXiv:2606.13663) measured baseline multi-step tool orchestration on MCP-Universe at just
  **9.93% for Qwen3-8B and 15.69% for Qwen3-32B** — improvable only to ~33-35% via a structural fix
  (bundling steps into single executable code blocks, not letting the model freely sequence individual
  calls). Evoflux (arXiv:2606.12674) finds baseline small-planner execution feasibility around **3%**
  on MCP-Bench, rising to only 17-24% with a self-repair mechanism. TOBench (arXiv:2605.16909) — a
  benchmark using **Claude Opus 4.6**, a frontier cloud model — gets only **32.0%** success against a
  94.0% human baseline on closed-loop multi-tool orchestration. OSWorld-MCP (arXiv:2510.24563) finds
  even o3/Claude Sonnet only achieve ~36.3% *correct tool invocation*. SOPBench (arXiv:2503.08669) and
  AgentBench (arXiv:2308.03688) both separately confirm 7-8B (and generally sub-70B) models trail
  frontier-scale models substantially on procedure-following and multi-environment agentic tasks. This
  is not a small-model problem specifically — it is evidence that open-ended multi-step tool
  orchestration is a largely unsolved problem at any accessible scale, and an on-device 4-8B model is
  not where to bet on solving it first.
- **Constrained, single-turn (or shallow) tool selection is a genuinely different and solved problem at
  this size.** Octopus (arXiv:2404.01549) and Octopus v2 (HF-2404.01744) fine-tune 2-7B on-device models
  with *conditional function masking* over a known API set and report they **outperform GPT-4** on
  function-call accuracy, with Octopus v2 also reporting a 35x latency win over a Llama-7B+RAG baseline.
  Hammer (HF-2410.04587) reaches SOTA on-device function-calling robustness the same way — masking the
  candidate function space, not leaving it open. DroidCall (HF-2412.00402) fine-tunes a **3B** model to
  approach GPT-4o specifically on **Android intent invocation** — the closest direct precedent to this
  project's own "invoke an internal app tool" use case. TinyAgent (HF-2409.00608) matches GPT-4-Turbo at
  1.1B-7B by combining fine-tuning with *tool retrieval* — narrowing the candidate set before the model
  chooses, not choosing freely from everything. The pattern repeats across every positive result found:
  **small models succeed at tool selection when the candidate set is masked and/or retrieval-narrowed
  first, and struggle badly the moment they must freely plan a multi-step sequence themselves.**
- **Two more direct design-pattern supports:** Less-is-More (HF-2411.15399) shows dynamically narrowing
  the exposed tool set before the model chooses cuts edge execution time ~70% and power ~40%. SMART
  (arXiv:2502.11435) shows explicitly *gating* whether a tool call happens at all (reducing unnecessary
  calls 24%) lets a 7B model match 70B-model performance — the win comes from calling less, not
  reasoning more freely. LLM-as-Code (arXiv:2606.15874) argues directly that deterministic control flow
  (the loop's sequencing and termination) should live in surrounding code, with the model only filling
  in well-defined decision points — this is a position/framework paper, not an empirical study, but it
  matches every empirical result above. ToolGym (arXiv:2601.06328) supports the same shape via a
  "planner-actor" decomposition that also improved data efficiency for fine-tuning.
- **Documented failure modes to guard against regardless of design:** hallucinated tool calls (World
  Modelling, arXiv:2506.02918, proposes outcome-prediction as a mitigation); wrong argument formatting,
  which IFEval-FC (arXiv:2509.18420) found even SOTA models frequently fail; "similar tool confusion"
  and "parameter-blind selection" that *worsen* as trajectories get longer (TRAJECT-Bench,
  arXiv:2510.04550); tool-argument accuracy collapsing 50-64 points moving from curated benchmarks to
  realistic queries (ToolSense, arXiv:2606.12451); and unbounded/infinite agentic loops with no natural
  stopping signal (arXiv:2607.01641) — a documented failure mode this project must design against
  explicitly, not assume away.
- **Resulting design rule, directly answering the "autonomous orchestration, no OS reach" scope chosen
  for this upgrade:** the existing code-governed state machine (`Orchestrator`/`FeedbackLoop`/
  `GamificationEngine`, and the README's own `Sense → Model → Detect → Explain → Intervene → Measure →
  Adapt` loop) stays exactly that — deterministic control flow in code. What becomes genuinely more
  agentic: at specific, well-scoped decision points (chiefly, GoalContext retrieval — see
  IMPLEMENTATION.md §4.5/§4.8), the model chooses from a **small, masked candidate set** (the known
  GoalContext sources: notes, todos, health targets, calendar, capture history — ≤5 options) rather than
  the previous fixed "always retrieve from all sources" behavior, with every call schema-validated
  before execution and a hard cap on chained calls per decision point (falling back to the old flat-
  bullet behavior if the cap is hit). This is a real increase in autonomy — the model now decides *what
  it needs to know*, not just how to phrase a fixed input — bounded exactly where the evidence above
  says on-device models are actually reliable, not where they're evidenced to fail.

### Concurrent multi-model serving: plausible on paper, genuinely untested in the literature

- **Rough RAM math, stated as arithmetic, not a citation:** eDKM (arXiv:2309.00964) compresses a 7B-class
  model's weights from 12.6GB to 2.5GB at 3-bit; scaling that down, a 4-bit-quantized Qwen3-4B is
  plausibly ~2-2.5GB of weights, with peak runtime RAM (KV-cache + activations) landing somewhere around
  3-4GB — MELTing Point (arXiv:2403.12844) and "Are We There Yet?" both stress that inference is
  memory-bound and peak RAM exceeds weight size for exactly this reason. Add EmbeddingGemma-300M
  (well under 1GB) and the capture pipeline's vision models (EdgeSAM + DocScanner + PP-OCRv5/6, likely a
  few hundred MB combined). **Total estimate: roughly 4-6GB peak for all on-device models resident at
  once** — comfortably inside a 16GB device even accounting for OS and app overhead, on paper.
- **No paper in this survey validates that math for a phone.** ConsumerBench (arXiv:2506.17538) is the
  closest direct hit — it explicitly benchmarks multiple concurrent GenAI workloads and finds real
  resource-contention and unfair-scheduling effects — but it targets consumer *desktop GPU* hardware, not
  phone NPU. Every other relevant source is either single-model memory-bound analysis (MELTing Point,
  "Are We There Yet?", MobileQuant) or a server-GPU technique (PagedAttention's KV-cache paging, vLLM)
  not ported to mobile NPU. **Nothing found tests 3 heterogeneous models (LLM + embedder + vision)
  resident simultaneously on phone-class hardware.** Treat the RAM estimate above as a plausible
  starting hypothesis to verify on the actual device, not a settled conclusion.
- **A real, separate risk even if capacity is sufficient: memory bandwidth, not just RAM capacity.**
  "AI and Memory Wall" (arXiv:2403.14123) argues memory bandwidth — not compute or even capacity — is
  the dominant bottleneck for LLM serving generally; three models contending for the same phone's memory
  bus could slow each other down even with 16GB of headroom to spare. This is a distinct failure mode
  from OOM and needs its own device-testing pass (concurrent latency under load, not just peak RSS).
- **Concrete fallback techniques if contention shows up in testing**, ranked by integration cost: (1)
  EdgeFlow (arXiv:2604.09083) and Execution-State Capsules (arXiv:2606.20537) both report large cold-
  start/restore speedups (4.07x and 3.9-27x respectively) — useful if the team decides to *swap* models
  in/out of memory (time-share the NPU) rather than keep all three resident simultaneously; (2) T-MAC
  (arXiv:2407.00088) offers a CPU-based low-bit inference path — running the vision pipeline on CPU
  instead of NPU would remove it from NPU contention with the LLM entirely, at a throughput cost; (3)
  MobileQuant (arXiv:2408.13933, already in the original RESEARCH.md "Also relevant") remains the first
  lever to try if any single model's own footprint (not cross-model contention) is the bottleneck.

---

## Open questions / risks

- **Cold start on a loaner/demo phone.** The device you build on for a week won't be the device judges see it on. The Bayesian population-prior blend (concept #3 above) is not optional — it's the only way the demo works on unfamiliar hardware with no usage history.
- **On-device SLM latency is unverified on Snapdragon.** No literature source measured this. Budget real device-testing time early (see IMPLEMENTATION.md day plan) rather than assuming the ~1GB Gemma 3 1B GGUF hits interactive latency.
- **NotificationListenerService and SYSTEM_ALERT_WINDOW-class permissions require manual user grants** via Settings, not a runtime permission dialog — this is a common demo-day failure mode (forgetting to pre-grant on the loaner device). Script this into the setup checklist, not the live demo.
- **"App-switching frequency" and "fragmentation" have no literature-backed threshold** — expect to hand-tune against your own logged usage, and keep the threshold logic in one clearly isolated, easily-tunable module so last-minute calibration doesn't touch the rest of the app.
- **Two on-device models loaded simultaneously** (Gemma 3 1B generator + EmbeddingGemma 300M retriever, ~1.3GB combined) is unverified on the loaner Snapdragon device — test concurrent memory pressure on Day 1 alongside the generator-only latency test, not as an afterthought once the goal-context layer is built. Arctic-Embed-XS (22.5M) is the fallback if this is a problem.
- **"Grounding in goals improves intervention outcomes" is this project's own hypothesis, not a proven literature claim** — the closest study (arXiv:2505.23997) is qualitative-only, N=8. Don't overclaim this in the pitch; frame it as "informed by the literature, validated by our own feedback-loop data," which is both honest and still a strong technical-depth story.
- **Cross-source fusion is explicitly out of scope** (see "Expansion" section above) — the risk is scope creep during the battle: the temptation to make the SLM "reason across" notes+todos+calendar+health in one open-ended prompt. Resist it; the literature says even frontier models struggle at 34.5% pass@1 on exactly this. Keep retrieval-per-source-type and combine only at the flat-prompt-assembly step.
- **No paper does freeform-scribble-to-clean-crop + document rectification end-to-end.** Expect to compose an EdgeSAM-class segmentation model with a DocScanner-class rectification model as genuinely first-party integration work, not a model to just download — and budget device-testing time for both, same as the SLM's unverified Snapdragon-latency risk above.
- **Whether captured images need a dedicated image embedding (MobileCLIP2) or can rely on OCR text through the existing EmbeddingGemma pipeline is a genuine open call, not a settled one.** DSE/UniSE argue dedicated screenshot embedding wins on text-dense images; CIVIL argues caption-then-text-embedding is enough. The MVP defers this and ships OCR+text-embedding only — a dedicated image embedder is a measured upgrade, never a default add.
- **Gamification is in direct, evidence-backed tension with the app's own anti-overload mission**, and the literature does not resolve this cleanly — arXiv:2411.09706 documents streaks/badges helping attainment *and* independently increasing anxiety and compulsive checking, as one real finding, not two competing ones to pick between. Mitigate with the reward-completion-not-avoidance design rule and the pre-ship dark-patterns self-audit (§ "Expansion: gamified capture-to-organize layer" above) — adding streaks/XP is not "done" until that audit has run.
- **No paper benchmarks a 7B+ agentic model's real end-to-end chat/agent latency on an actual phone-class Snapdragon 8-Gen/Elite NPU.** The closest numbers are phone-*GPU* (not NPU), NPU-*prefill-only* (not decode), or laptop-class Snapdragon X Elite (not the phone Hexagon NPU) — see § "Expansion: flagship-hardware agentic upgrade." Day 1 of testing the upgraded model is the first real measurement, exactly like the original 1B model's latency question.
- **No paper validates 3 heterogeneous on-device models (agentic LLM + embedder + vision pipeline) running concurrently on phone-class hardware.** The RAM math is plausible (~4-6GB peak estimated vs. 16GB available) but unverified, and memory *bandwidth* contention — a distinct risk from running out of RAM — has no phone-specific evidence either way. Test combined memory pressure and concurrent-load latency directly, not just each model in isolation.
- **Multi-step tool orchestration is a largely unsolved problem even for frontier cloud models** (32-36% success in the benchmarks cited in § "Expansion: flagship-hardware agentic upgrade," using Claude Opus 4.6/o3/Claude Sonnet). The masked, code-governed tool-selection design in that section is a hard requirement for this project, not a simplified starting point to relax later as the model "proves itself" — the evidence says open-ended orchestration doesn't get more reliable with a slightly bigger on-device model, it stays broken in the same way.
