cmake_minimum_required(VERSION 3.22.1)

project(atari_model_jni LANGUAGES CXX)

get_filename_component(ATARI_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../../../.." ABSOLUTE)
set(ATARI_MODEL_ROOT "${ATARI_ROOT}/native/model")

add_library(atari_model_jni SHARED
  "${ATARI_MODEL_ROOT}/src/atari_model_jni.cpp"
  "${ATARI_MODEL_ROOT}/src/explanation_service.cpp"
  "${ATARI_MODEL_ROOT}/src/source_selection_service.cpp"
)

target_include_directories(atari_model_jni PRIVATE
  "${ATARI_MODEL_ROOT}/include"
)

target_compile_features(atari_model_jni PRIVATE cxx_std_17)
target_compile_options(atari_model_jni PRIVATE -Wall -Wextra -Wpedantic -Werror)
