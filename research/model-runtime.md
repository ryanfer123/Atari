# On-device model runtime decision

Status: full-model device gate complete; smaller-model comparison required

Date: 2026-08-29

## Decision

Use the maintained upstream `llama.cpp` Android binding as ATARI's GGUF runtime.
Qwen3-4B Q4_K_M is now a proven quality/reference candidate, but it does not pass
the resident-memory gate as the default model yet. Benchmark Gemma 3 1B QAT Q4_0
or a comparable sub-1B model next, then choose using the same prompt contract.

Do not fine-tune a model for the MVP. First establish whether constrained prompting
plus output validation meets the explanation-quality bar.

## Why this model

The official Qwen3-4B GGUF repository publishes Q4_K_M weights, documents direct
`llama.cpp` use, and licenses the model under Apache-2.0. Qwen3 supports explicit
thinking/non-thinking switching. ATARI appends `/no_think` because its two model
tasks are short, latency-sensitive, and independently validated in native code.

The model's task is intentionally narrow:

```text
structured behavioral evidence + typed context bullets → one grounded, supportive sentence
closed source allow-list + overload signals → one schema-constrained source array
```

General benchmark scores do not validate that specific task. ATARI therefore
needs its own prompt evaluation set and real-device measurements.

## Runtime comparison

### llama.cpp

Advantages:

- direct support for the official Qwen3 Q4_K_M GGUF
- maintained upstream Android example
- model metadata parsing, app-private model loading, chat-template application,
  streaming token generation, and a benchmark entry point already exist upstream
- broad CPU compatibility and a replaceable native API

Risks:

- CPU performance, memory, and thermals remain device-specific
- native-source integration increases build surface
- acceleration availability varies by SoC and backend

Pinned research revision: `d7bd3bfcad3e29c7e49fd26f38c79ee3e9a3fd6b`.

### LiteRT-LM comparison

Advantages:

- official Android-focused edge runtime with stable Kotlin and C++ APIs
- CPU, GPU, and NPU execution paths
- prebuilt Android integration and a smaller Gemma 3 1B four-bit artifact are
  documented upstream

Risks:

- uses `.litertlm` rather than the selected official Qwen3 GGUF artifact
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
2. Goal and note context is typed and treated as untrusted data, not instructions.
3. Generation is short and conservative.
4. Outputs containing diagnostic language, prompt leakage, multiple sentences,
   control characters, or excessive length are rejected.
5. Runtime unavailability, inference errors, and invalid output use a deterministic
   explanation instead.
6. Context-source selection is JSON-schema constrained to a per-request closed enum, then parsed and
   validated again in native code with a three-source cap and a no-retry fixed fallback.
7. Fragmentation detection, retrieval, interventions, and gamification remain deterministic.

## Device benchmark gate

The full Qwen3-4B Q4_K_M device gate completed on 2026-08-29. The iQOO 15 loaded
the 2,497,280,256-byte GGUF through the ARMv9.2 GGML CPU backend and produced a
contract-valid sentence. The first run generated in 5.988 seconds, while a second
bounded-context run took 29.500 seconds under substantially higher swap pressure.

The upstream 8192-token context allocated a 1152 MiB KV cache. ATARI's bounded
1024-token patch reduced that cache to 144 MiB and reduced observed RSS from about
4.95 GiB to 4.51 GiB, but total PSS remained around 5.15 GiB and swap rose to about
797 MiB in the second run. This proves compatibility and useful output, but not a
safe always-resident configuration alongside OCR and embedding models.

Evidence is recorded in:

- `research/device-results/2026-08-29-iqoo-15-runtime-smoke.json`
- `research/device-results/2026-08-29-iqoo-15-qwen3-4b-inference.json`

Run the selected smaller comparison model against the same prompt set and record:

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
- [Official Qwen3-4B GGUF](https://huggingface.co/Qwen/Qwen3-4B-GGUF)
- [Qwen3 thinking and non-thinking modes](https://github.com/QwenLM/Qwen3/blob/main/docs/source/inference/transformers.md)
- [llama.cpp](https://github.com/ggml-org/llama.cpp)
- [llama.cpp Android example](https://github.com/ggml-org/llama.cpp/tree/master/examples/llama.android)
- [llama.cpp JSON-schema constrained generation](https://github.com/ggml-org/llama.cpp/blob/master/grammars/README.md)
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
