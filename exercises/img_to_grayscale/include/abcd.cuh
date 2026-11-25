#pragma once

#include <stdio.h>
#include <memory>

#define CUDA_CHECK(call)\
    do {\
        cudaError_t err = (call);\
        if(err != cudaSuccess)\
        {\
            std::fprintf(stderr, "CUDA error at %s:%d\n Call: %s\n Error: %s\n",\
          __FILE__, __LINE__, #call,\
          cudaGetErrorString(err));\
          std::abort();\
        }\
    } while(0)

#define CUDA_KERNEL_CHECK()\
    do{\
        CUDA_CHECK(cudaGetLastError());\
        CUDA_CHECK(cudaDeviceSynchronize());\
    } while(0)
