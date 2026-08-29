# ATARI llama.cpp Android integration

This directory records the reproducible overlay used to turn upstream
`examples/llama.android` into ATARI's physical-device inference harness.

The overlay adds two intent extras to the sample activity:

- `atari_model_path`: an absolute path readable by the app
- `atari_prompt`: a bounded prompt to run immediately after model load

The activity logs one of these stable markers:

- `ATARI_INFERENCE_STARTED`
- `ATARI_INFERENCE_COMPLETE elapsedMs=... output=...`
- `ATARI_INFERENCE_ERROR ...`

Apply the patch to the pinned `llama.cpp` revision documented in
`research/model-runtime.md`, build `:app:assembleDebug`, and use
`scripts/deploy-qwen3-android.sh` to install the APK and model.

Model weights are deliberately excluded from Git.
