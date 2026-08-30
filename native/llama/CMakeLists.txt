cmake_minimum_required(VERSION 3.22.1)
project(atari_llama CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# llama.cpp is a shallow clone, not a committed subtree — see
# scripts/fetch-llama.sh. Failing loudly here beats a wall of missing
# header errors.
set(LLAMA_CPP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp")
if(NOT EXISTS "${LLAMA_CPP_DIR}/CMakeLists.txt")
    message(FATAL_ERROR
        "llama.cpp is not checked out at ${LLAMA_CPP_DIR}. "
        "Run scripts/fetch-llama.sh first.")
endif()

# Only the library is wanted. The tools, tests, server and examples pull
# in extra dependencies and add minutes to every Android build.
set(LLAMA_BUILD_TESTS    OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TOOLS    OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_SERVER   OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_COMMON   OFF CACHE BOOL "" FORCE)
set(LLAMA_CURL           OFF CACHE BOOL "" FORCE)

# The NDK ships no OpenMP runtime by default; leaving this on fails the
# link. ggml falls back to its own thread pool, which is what the
# Android builds upstream use too.
set(GGML_OPENMP OFF CACHE BOOL "" FORCE)

# The NDK targets baseline armv8-a, which has no fp16 vector intrinsics
# — ggml's llamafile sgemm then fails to compile outright (`vld1q_f16`
# undeclared). Raising the baseline fixes that and, more importantly,
# switches on the dotprod and fp16 kernels that carry quantized
# inference. Every arm64 phone this app targets is armv8.2 or newer.
set(GGML_CPU_ARM_ARCH "armv8.2-a+dotprod+fp16" CACHE STRING "" FORCE)

add_subdirectory(${LLAMA_CPP_DIR} ${CMAKE_CURRENT_BINARY_DIR}/llama.cpp EXCLUDE_FROM_ALL)

add_library(atari_llama SHARED atari_llama.cpp)

target_link_libraries(atari_llama
    PRIVATE
        llama
        ggml
        android
        log
)
