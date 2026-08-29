cmake_minimum_required(VERSION 3.16)

project(atari_model_contract LANGUAGES CXX)

add_library(atari_model_contract STATIC
  src/explanation_service.cpp
)

target_include_directories(atari_model_contract
  PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_compile_features(atari_model_contract PUBLIC cxx_std_17)

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
  target_compile_options(atari_model_contract PRIVATE -Wall -Wextra -Wpedantic -Werror)
endif()

option(ATARI_MODEL_BUILD_TESTS "Build model contract tests" ON)

if(ATARI_MODEL_BUILD_TESTS)
  enable_testing()

  add_executable(atari_model_contract_tests
    tests/explanation_service_test.cpp
  )

  target_link_libraries(atari_model_contract_tests PRIVATE atari_model_contract)

  if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
    target_compile_options(atari_model_contract_tests PRIVATE -Wall -Wextra -Wpedantic -Werror)
  endif()

  add_test(NAME atari_model_contract_tests COMMAND atari_model_contract_tests)
endif()
