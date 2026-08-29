# Native inference

This directory contains the runtime-independent model contract and will contain
the selected C/C++ runtime adapter exposed to Flutter or the Android host.

```text
native/
├── model/             Tested prompt, output, and fallback contract
└── llama/             Planned llama.cpp Android runtime adapter
```

Model weights are intentionally excluded from Git.
