#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 <debug-apk> <Qwen3-4B-Q4_K_M.gguf> [prompt]" >&2
  exit 2
fi

apk_path="$1"
model_path="$2"
prompt="${3:-You are ATARI's on-device explanation component. Write exactly one supportive sentence using no more than 28 words. Do not diagnose, expose scores, invent causes, or give advice. /no_think Evidence: app switching is above the user's usual Tuesday-afternoon baseline.}"
package_name="com.example.llama.aichat"
activity_name="com.example.llama.MainActivity"
expected_model_bytes=2497280256
staging_model_path="/sdcard/Download/Qwen3-4B-Q4_K_M.gguf"
private_model_relative="files/models/Qwen3-4B-Q4_K_M.gguf"
private_model_path="/data/user/0/${package_name}/${private_model_relative}"

[[ -f "$apk_path" ]] || { echo "APK not found: $apk_path" >&2; exit 1; }
[[ -f "$model_path" ]] || { echo "Model not found: $model_path" >&2; exit 1; }

actual_model_bytes="$(stat -f %z "$model_path")"
if [[ "$actual_model_bytes" != "$expected_model_bytes" ]]; then
  echo "Unexpected model size: $actual_model_bytes (expected $expected_model_bytes)" >&2
  exit 1
fi

adb get-state >/dev/null
adb install -r "$apk_path"
adb shell run-as "$package_name" mkdir -p files/models

device_bytes="$(adb shell run-as "$package_name" stat -c %s "$private_model_relative" 2>/dev/null | tr -d '\r' || true)"
if [[ "$device_bytes" != "$expected_model_bytes" ]]; then
  staging_bytes="$(adb shell stat -c %s "$staging_model_path" 2>/dev/null | tr -d '\r' || true)"
  if [[ "$staging_bytes" != "$expected_model_bytes" ]]; then
    adb push "$model_path" "$staging_model_path"
  fi
  adb shell "cat '$staging_model_path' | run-as '$package_name' dd of='$private_model_relative' bs=4M"
fi

device_bytes="$(adb shell run-as "$package_name" stat -c %s "$private_model_relative" | tr -d '\r')"
if [[ "$device_bytes" != "$expected_model_bytes" ]]; then
  echo "Device model size verification failed: $device_bytes" >&2
  exit 1
fi

adb logcat -c
adb shell am force-stop "$package_name"
prompt_base64="$(printf '%s' "$prompt" | base64 | tr -d '\n')"
adb shell am start -n "${package_name}/${activity_name}" \
  --es atari_model_path "$private_model_path" \
  --es atari_prompt_b64 "$prompt_base64"

echo "Started ATARI inference. Watch with:"
echo "adb logcat -s MainActivity:I '*:S'"
