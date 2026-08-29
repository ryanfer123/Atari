# Model explanation contract

This module defines the runtime-independent boundary between ATARI's deterministic
behaviour engine and an on-device language model.

It currently provides:

- typed behavioural evidence
- bounded generation settings
- prompt construction with an explicit trust boundary
- generated-output validation
- deterministic, signal-specific fallback explanations
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

The model may phrase a supportive explanation. It does not detect fragmentation,
choose an intervention, award XP, change streaks, or diagnose the user.
