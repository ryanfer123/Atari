cmake_minimum_required(VERSION 3.31.6)

project(atari_model_jni LANGUAGES CXX)

get_filename_component(ATARI_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../../../.." ABSOLUTE)
set(ATARI_MODEL_ROOT "${ATARI_ROOT}/native/model")
set(LLAMA_ROOT "${ATARI_ROOT}/android/third_party/llama.cpp")

set(BUILD_SHARED_LIBS ON CACHE BOOL "" FORCE)
set(LLAMA_BUILD_COMMON ON CACHE BOOL "" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "" FORCE)
set(LLAMA_OPENSSL OFF CACHE BOOL "" FORCE)
set(GGML_NATIVE OFF CACHE BOOL "" FORCE)
set(GGML_BACKEND_DL ON CACHE BOOL "" FORCE)
set(GGML_CPU_ALL_VARIANTS ON CACHE BOOL "" FORCE)
set(GGML_LLAMAFILE OFF CACHE BOOL "" FORCE)

add_subdirectory("${LLAMA_ROOT}" "${CMAKE_CURRENT_BINARY_DIR}/llama")

add_library(atari_model_jni SHARED
  "${ATARI_MODEL_ROOT}/src/atari_model_jni.cpp"
  "${CMAKE_CURRENT_LIST_DIR}/atari_llama_runtime.cpp"
  "${ATARI_MODEL_ROOT}/src/explanation_service.cpp"
  "${ATARI_MODEL_ROOT}/src/source_selection_service.cpp"
)

target_include_directories(atari_model_jni PRIVATE
  "${ATARI_MODEL_ROOT}/include"
  "${LLAMA_ROOT}/include"
  "${LLAMA_ROOT}/ggml/include"
)

target_compile_features(atari_model_jni PRIVATE cxx_std_17)
target_compile_options(atari_model_jni PRIVATE -Wall -Wextra -Wpedantic)

target_link_libraries(atari_model_jni
  llama
  android
  log
)
