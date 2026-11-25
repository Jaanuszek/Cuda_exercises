#include <iostream>
#include <memory>
#include <vector>

#define STB_IMAGE_IMPLEMENTATION
#include "stb/stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb/stb_image_write.h"

#include "cuda_common.cuh"

__global__ void png_to_gray_scale(unsigned char* img_data, unsigned char* out_data, int w, int h, int n)
{
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int row = blockIdx.y * blockDim.y + threadIdx.y;

    if(col < w && row < h)
    {
        int grayOffset = row * w + col;
        int rgbOffset = grayOffset * n;
        unsigned char r = img_data[rgbOffset];
        unsigned char g = img_data[rgbOffset + 1];
        unsigned char b = img_data[rgbOffset + 2];
        if(n > 3)
            unsigned char a = img_data[rgbOffset + 3];
        out_data[grayOffset] = (unsigned char) 0.21f * r + 0.71 * g + 0.07f * b;
    }
}

int main()
{
    int img_w, img_h, n;
    unsigned char* img_data = stbi_load("radiosity_patch.png", &img_w, &img_h, &n, 0);
    const int img_size_bytes = img_w * img_h * n;

    if(!img_data)
    {
        std::cout << "img_data empty!\n";
        return -1;
    }

    cudaPtr<unsigned char> img_data_d = make_cuda_unique<unsigned char>(img_size_bytes);
    // without n since its going to to be a gray scale img
    cudaPtr<unsigned char> out_img_d = make_cuda_unique<unsigned char>(img_w * img_h);

    CUDA_CHECK(cudaMemcpy(img_data_d.get(), img_data, img_size_bytes, cudaMemcpyHostToDevice));

    const int TILE_X = 16;
    const int TILE_Y = 16;
    dim3 threadsPerBlock(TILE_X, TILE_Y, 1);
    dim3 blockSize(
        (img_w + TILE_X - 1) / TILE_X,
        (img_h + TILE_Y - 1) / TILE_Y,
        1);
    png_to_gray_scale<<<blockSize, threadsPerBlock>>>(img_data_d.get(), out_img_d.get(), img_w, img_h, n);
    CUDA_KERNEL_CHECK();

    std::vector<unsigned char> out_h(img_w * img_h);
    CUDA_CHECK(cudaMemcpy(out_h.data(), out_img_d.get(), img_w * img_h, cudaMemcpyDeviceToHost));

    if(!stbi_write_png("newImg.png", img_w, img_h, 1, (void*)out_h.data(), img_w * 1))
    {
        std::cout << "stbi_write_png failure\n";
    }

    stbi_image_free(img_data);
}
