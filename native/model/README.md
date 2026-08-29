# Model explanation contract

This module defines the runtime-independent boundary between ATARI's deterministic
behaviour engine and an on-device language model.

It currently provides:

- typed behavioural evidence
- typed context bullets matching the Flutter `Explanation` contract
- bounded generation settings
- prompt construction with an explicit trust boundary
- Qwen3 non-thinking prompts for short on-device requests
- JSON-schema-constrained selection from the five allowed context sources
- generated-output validation
- deterministic explanation and source-retrieval fallbacks
- a replaceable `ModelRuntime` interface

It intentionally does not load model weights. Android runtime adapters will
implement `ModelRuntime` using the selected on-device engine after the same-device
benchmark spike.

## Build and test

```bash
cmake -S native/model -B build/model-contract
cmake --build build/model-contract
ctest --test-dir build/model-contract --output-on-failure
```

Or run:

```bash
./scripts/test-model-contract.sh
```

## Ownership boundary

The model may phrase a supportive explanation and select up to three context sources
from a per-request allow-list. It cannot retrieve records itself. It does not detect
fragmentation, choose an intervention, award XP, change streaks, or diagnose the user.
