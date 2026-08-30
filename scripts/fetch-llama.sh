#!/usr/bin/env bash
# Fetches the llama.cpp checkout the Android native build compiles
# against.
#
# It is deliberately not a git submodule: the Android build only needs a
# shallow tree, and a submodule would make every clone of this repo pull
# ~200MB whether or not the developer is building native code.
#
# Pinned to an exact commit so a native build is reproducible. Bumping
# it is a deliberate act — llama.cpp's C API changes often enough that
# native/llama/atari_llama.cpp usually needs a look at the same time.
set -euo pipefail

# Verified to support Qwen3 (LLM_ARCH_QWEN3) and EmbeddingGemma
# (LLM_ARCH_GEMMA_EMBEDDING), which are the two models ATARI loads.
LLAMA_COMMIT="3173a56471c1753650cd806694145ffd6dcace67"
LLAMA_REPO="https://github.com/ggml-org/llama.cpp.git"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target="$repo_root/native/llama/llama.cpp"

if [ -d "$target/.git" ]; then
    current="$(git -C "$target" rev-parse HEAD)"
    if [ "$current" = "$LLAMA_COMMIT" ]; then
        echo "llama.cpp already at $LLAMA_COMMIT"
        exit 0
    fi
    echo "Updating llama.cpp from $current to $LLAMA_COMMIT"
    git -C "$target" fetch --depth 1 origin "$LLAMA_COMMIT"
    git -C "$target" checkout -f FETCH_HEAD
else
    echo "Cloning llama.cpp at $LLAMA_COMMIT"
    rm -rf "$target"
    mkdir -p "$(dirname "$target")"
    git init -q "$target"
    git -C "$target" remote add origin "$LLAMA_REPO"
    git -C "$target" fetch --depth 1 origin "$LLAMA_COMMIT"
    git -C "$target" checkout -f FETCH_HEAD
fi

echo "llama.cpp ready at $target"
