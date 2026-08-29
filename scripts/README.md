# Scripts

Place repeatable development, validation, build, migration, and release
automation here. Scripts should fail clearly, avoid hidden machine-specific
assumptions, and be safe to run more than once where possible.

Available scripts:

- `test-model-contract.sh` builds and runs the native explanation-contract tests.
- `benchmark-android-runtime-smoke.sh` records physical-device runtime startup,
  idle memory, frame, thermal, battery, and loaded-library evidence. Set
  `ANDROID_SERIAL` when more than one adb target is connected. Artifacts default
  to a new temporary directory.
