cmake_minimum_required(VERSION 3.28)

project(MAT_MUL_BASIC C CXX CUDA)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 20)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_ARCHITECTURES native)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(INCLUDE_LIB includes_lib)
set(EXTERNAL_LIB external_lib)

add_subdirectory(
  ${CMAKE_CURRENT_SOURCE_DIR}/../../common
  ${CMAKE_BINARY_DIR}/common_lib/
)

add_library(${INCLUDE_LIB})

target_sources(
  ${INCLUDE_LIB}
  PRIVATE
    src/abcd.cu
  PUBLIC
    FILE_SET HEADERS
      BASE_DIRS
        include
      FILES
        include/abcd.cuh
)

add_library(${EXTERNAL_LIB} INTERFACE)

# target_sources(
#   ${EXTERNAL_LIB}
#   INTERFACE
#     FILE_SET HEADERS
#       BASE_DIRS
#         ${CMAKE_CURRENT_SOURCE_DIR}/../../external
#       FILES
#         ${CMAKE_CURRENT_SOURCE_DIR}/../../external/stb/stb_image.h
#         ${CMAKE_CURRENT_SOURCE_DIR}/../../external/stb/stb_image_write.h
# )
target_include_directories(
  ${EXTERNAL_LIB}
  INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/../../external
)

add_executable(${PROJECT_NAME})

# target_compile_options(${PROJECT_NAME} PRIVATE
    # $<$<COMPILE_LANGUAGE:CUDA>:-lineinfo;-G;-g>
    # $<$<COMPILE_LANGUAGE:CUDA>:-lineinfo>
    # $<$<COMPILE_LANGUAGE:CXX>:-g;-O0>
# )

target_sources(${PROJECT_NAME}
  PRIVATE
  main.cu
)

target_link_libraries(
  ${PROJECT_NAME}
  PRIVATE
    ${INCLUDE_LIB}
    ${EXTERNAL_LIB}
    ${COMMON_LIB}
)
