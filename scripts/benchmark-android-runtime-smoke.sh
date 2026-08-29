#!/usr/bin/env bash

set -euo pipefail

package_name="${1:-com.example.llama.aichat}"
activity_name="${2:-com.example.llama.MainActivity}"
measured_runs="${3:-5}"
artifact_dir="${4:-}"

if ! [[ "$measured_runs" =~ ^[1-9][0-9]*$ ]]; then
  echo "measured_runs must be a positive integer" >&2
  exit 2
fi

if ! command -v adb >/dev/null 2>&1; then
  echo "adb is required" >&2
  exit 2
fi

if [[ -z "$artifact_dir" ]]; then
  artifact_dir="$(mktemp -d "${TMPDIR:-/tmp}/atari-android-smoke.XXXXXX")"
else
  mkdir -p "$artifact_dir"
fi

adb_cmd=(adb)
if [[ -n "${ANDROID_SERIAL:-}" ]]; then
  adb_cmd+=(-s "$ANDROID_SERIAL")
fi
device_state="$("${adb_cmd[@]}" get-state 2>/dev/null || true)"
if [[ "$device_state" != "device" ]]; then
  echo "No authorized adb device is available" >&2
  exit 1
fi

component="$package_name/$activity_name"

{
  printf 'captured_at_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'package=%s\n' "$package_name"
  printf 'activity=%s\n' "$activity_name"
  printf 'manufacturer=%s\n' "$("${adb_cmd[@]}" shell getprop ro.product.manufacturer | tr -d '\r')"
  printf 'brand=%s\n' "$("${adb_cmd[@]}" shell getprop ro.product.brand | tr -d '\r')"
  printf 'marketing_name=%s\n' "$("${adb_cmd[@]}" shell getprop ro.vivo.product.release.name | tr -d '\r')"
  printf 'model=%s\n' "$("${adb_cmd[@]}" shell getprop ro.product.model | tr -d '\r')"
  printf 'soc=%s\n' "$("${adb_cmd[@]}" shell getprop ro.soc.model | tr -d '\r')"
  printf 'android=%s\n' "$("${adb_cmd[@]}" shell getprop ro.build.version.release | tr -d '\r')"
  printf 'api=%s\n' "$("${adb_cmd[@]}" shell getprop ro.build.version.sdk | tr -d '\r')"
  printf 'abi=%s\n' "$("${adb_cmd[@]}" shell getprop ro.product.cpu.abilist | tr -d '\r')"
  printf 'build_fingerprint=%s\n' "$("${adb_cmd[@]}" shell getprop ro.build.fingerprint | tr -d '\r')"
} > "$artifact_dir/device.txt"

"${adb_cmd[@]}" shell dumpsys battery > "$artifact_dir/battery-before.txt"
"${adb_cmd[@]}" shell dumpsys thermalservice > "$artifact_dir/thermal-before.txt"
"${adb_cmd[@]}" shell dumpsys gfxinfo "$package_name" reset >/dev/null 2>&1 || true

printf 'run\tlaunch_state\tactivity\ttotal_time_ms\twait_time_ms\n' > "$artifact_dir/cold-start.tsv"
for run in $(seq 1 "$measured_runs"); do
  start_output="$("${adb_cmd[@]}" shell am start -W -S --activity-clear-task -n "$component")"
  launch_state="$(printf '%s\n' "$start_output" | awk -F': ' '/^LaunchState:/ {print $2}')"
  reported_activity="$(printf '%s\n' "$start_output" | awk -F': ' '/^Activity:/ {print $2}')"
  total_time="$(printf '%s\n' "$start_output" | awk -F': ' '/^TotalTime:/ {print $2}')"
  wait_time="$(printf '%s\n' "$start_output" | awk -F': ' '/^WaitTime:/ {print $2}')"
  if [[ "$launch_state" != "COLD" || "$reported_activity" != "$component" ]]; then
    printf '%s\n' "$start_output" >&2
    echo "Run $run did not cold-launch $component" >&2
    exit 1
  fi
  printf '%s\t%s\t%s\t%s\t%s\n' \
    "$run" "$launch_state" "$reported_activity" "$total_time" "$wait_time" \
    >> "$artifact_dir/cold-start.tsv"
done

pid="$("${adb_cmd[@]}" shell pidof "$package_name" | tr -d '\r')"
if [[ -z "$pid" ]]; then
  echo "The app process did not remain alive after launch" >&2
  exit 1
fi

"${adb_cmd[@]}" shell dumpsys meminfo "$pid" > "$artifact_dir/meminfo.txt"
"${adb_cmd[@]}" shell dumpsys gfxinfo "$package_name" framestats > "$artifact_dir/gfxinfo.txt"
"${adb_cmd[@]}" shell dumpsys thermalservice > "$artifact_dir/thermal-after.txt"
"${adb_cmd[@]}" shell dumpsys battery > "$artifact_dir/battery-after.txt"
"${adb_cmd[@]}" shell run-as "$package_name" cat "/proc/$pid/maps" \
  | awk '$NF ~ /\/lib\/arm64\/lib(ai-chat|llama|ggml|omp)/ {print $NF}' \
  | sort -u > "$artifact_dir/loaded-native-libraries.txt"

echo "Runtime smoke artifacts: $artifact_dir"
