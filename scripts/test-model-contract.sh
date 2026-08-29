#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_directory="${project_root}/build/model-contract"

cmake -S "${project_root}/native/model" -B "${build_directory}"
cmake --build "${build_directory}"
ctest --test-dir "${build_directory}" --output-on-failure
