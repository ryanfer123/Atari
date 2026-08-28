# Native inference

This directory will contain the C/C++ runtime used for local model inference and
the bridge exposed to Flutter or the Android host.

```text
native/
└── llama/
    ├── llama.cpp integration
    └── ATARI inference bridge
```

Model weights are intentionally excluded from Git.
