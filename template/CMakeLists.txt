cmake_minimum_required(VERSION 3.28)

project(TEMPLATE C CXX CUDA)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 20)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_ARCHITECTURES native)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(INCLUDES_LIB includes_lib)

add_library(${INCLUDES_LIB})

target_sources(
  ${INCLUDES_LIB}
  PRIVATE
    src/abcd.cu
  PUBLIC
    FILE_SET HEADERS
      BASE_DIRS
        include
      FILES
        include/abcd.cuh
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
    ${INCLUDES_LIB}
)
