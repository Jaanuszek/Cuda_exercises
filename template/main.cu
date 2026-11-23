#include <iostream>

#include "abcd.cuh"

int main()
{
    int *d_ptr = nullptr;
    cudaMalloc((void**)&d_ptr, sizeof(int));
    cudaFree(d_ptr);

    foo();
}
