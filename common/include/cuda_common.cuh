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

struct cudaDeleter{
    void operator()(void* ptr) const {
        if(ptr)
            CUDA_CHECK(cudaFree(ptr));
    }
};

template <typename N>
using cudaPtr = std::unique_ptr<N, cudaDeleter>;

template <typename T>
cudaPtr<T> make_cuda_unique(std::size_t count)
{
    T* ptr = nullptr;
    CUDA_CHECK(cudaMalloc(reinterpret_cast<void**>(&ptr), count * sizeof(T)));
    return cudaPtr<T>(ptr);
}
