# On-device model runtime decision

Status: implementation spike in progress

Date: 2026-08-29

## Decision

Keep Gemma 3 1B Instruct QAT Q4_0 as ATARI's first explanation-model candidate.
Use the maintained upstream `llama.cpp` Android binding as the primary integration
reference, while preserving a runtime interface that allows a controlled
comparison with LiteRT-LM on the target iQOO device.

Do not fine-tune a model for the MVP. First establish whether constrained prompting
plus output validation meets the explanation-quality bar.

## Why this model

The official Gemma 3 technical report describes a 1B member designed for consumer
hardware. The official QAT repository supplies a four-bit GGUF and states that QAT
reduces memory while preserving similar quality to bfloat16. The 1B model is
text-only and has a 32K context window; ATARI will use only a small fraction of
that context.

The model's task is intentionally narrow:

```text
structured behavioral evidence → one grounded, supportive sentence
```

General benchmark scores do not validate that specific task. ATARI therefore
needs its own prompt evaluation set and real-device measurements.

## Runtime comparison

### llama.cpp

Advantages:

- direct support for the official Gemma QAT GGUF
- maintained upstream Android example
- model metadata parsing, app-private model loading, chat-template application,
  streaming token generation, and a benchmark entry point already exist upstream
- broad CPU compatibility and a replaceable native API

Risks:

- CPU performance, memory, and thermals remain device-specific
- native-source integration increases build surface
- acceleration availability varies by SoC and backend

Pinned research revision: `d7bd3bfcad3e29c7e49fd26f38c79ee3e9a3fd6b`.

### LiteRT-LM

Advantages:

- official Android-focused edge runtime with stable Kotlin and C++ APIs
- CPU, GPU, and NPU execution paths
- prebuilt Android integration and a smaller Gemma 3 1B four-bit artifact are
  documented upstream

Risks:

- uses `.litertlm` rather than the selected official GGUF artifact
- Flutter support is community-maintained, so ATARI would still use a Kotlin or
  native bridge
- changing runtime and model format together makes quality comparison less direct

Pinned research revision: `d5a221099373381c589d2fc2ad1b470745ae1fe0`.

## Correction to the preliminary plan

The preliminary plan states that PhoneLM supplies a working Android `llama.cpp`
harness. PhoneLM's repository actually documents its own `mllm` format and points
to the separate `mllm` runtime. ATARI should reference upstream `llama.cpp`'s
maintained `examples/llama.android` implementation instead of treating PhoneLM as
a Gemma/llama.cpp integration base.

PhoneLM remains useful research on phone-oriented small models, but it is not the
selected runtime harness.

## Safety and reliability contract

The runtime-independent contract enforces these rules before UI delivery:

1. Only finite, bounded, structured evidence enters the prompt.
2. Goal and note context is treated as untrusted data, not instructions.
3. Generation is short and conservative.
4. Outputs containing diagnostic language, prompt leakage, multiple sentences,
   control characters, or excessive length are rejected.
5. Runtime unavailability, inference errors, and invalid output use a deterministic
   explanation instead.
6. Fragmentation detection, interventions, and gamification remain deterministic.

## Device benchmark gate

The first physical-device runtime smoke test completed on 2026-08-29. The
upstream arm64 sample built, installed, launched, and loaded the
`armv9.2_2` GGML CPU backend on the iQOO 15. This proves runtime and ABI
compatibility, but it is not an inference benchmark because no model weights were
loaded. The captured baseline is in
`research/device-results/2026-08-29-iqoo-15-runtime-smoke.json`.

Run both viable runtimes against the same prompt set on the actual iQOO device and
record:

- model file size and installed footprint
- cold model-load latency
- time to first token
- prompt-processing tokens per second
- generation tokens per second
- peak resident memory
- warm-run median and p95 latency
- battery change during repeated runs
- device temperature and thermal throttling
- valid-output rate and fallback rate

Mobile inference research consistently treats latency, throughput, resource use,
battery, and thermal behavior as separate measurements. Desktop results are not a
substitute for this gate.

## Sources

- [Gemma 3 Technical Report](https://arxiv.org/abs/2503.19786)
- [Official Gemma 3 1B QAT Q4_0 GGUF](https://huggingface.co/google/gemma-3-1b-it-qat-q4_0-gguf)
- [llama.cpp](https://github.com/ggml-org/llama.cpp)
- [llama.cpp Android example](https://github.com/ggml-org/llama.cpp/tree/master/examples/llama.android)
- [LiteRT-LM](https://github.com/google-ai-edge/LiteRT-LM)
- [Mobile LLM performance measurement study](https://arxiv.org/abs/2410.03613)
- [Mobile and Edge Evaluation of Large Language Models](https://openreview.net/forum?id=aAtCQnCsya)
- [PhoneLM](https://github.com/UbiquitousLearning/PhoneLM)

## Product reference: Habitica

[Habitica](https://github.com/HabitRPG/habitica) validates the product pattern of
turning habits and tasks into an RPG loop with experience, health, gold, levels,
and rewards. ATARI will borrow that product concept, not Habitica's source code or
assets.

Habitica's code is GPLv3 and its project assets use Creative Commons licenses,
including a non-commercial license for Habitica-designed content. ATARI must keep
its implementation and visual assets original unless a future licensing decision
explicitly permits otherwise.

The integration boundary is:

```text
verified user action → deterministic progression engine → XP/reward transaction
                                                 ↓
                              optional model-written celebration
```

The language model may celebrate earned progress, but it never calculates or
awards XP.
