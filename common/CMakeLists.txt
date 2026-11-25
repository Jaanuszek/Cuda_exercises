cmake_minimum_required(VERSION 3.28)

set(COMMON_LIB common_lib PARENT_SCOPE) # it only saves variable in PARENT_SCOPE
set(COMMON_LIB common_lib) # it only saves variable in current (local) scope

add_library(${COMMON_LIB} INTERFACE)

target_sources(
  ${COMMON_LIB}
  INTERFACE
    FILE_SET HEADERS
      BASE_DIRS
        include
      FILES
        include/cuda_common.cuh
)

target_include_directories(
  ${COMMON_LIB}
  INTERFACE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)
