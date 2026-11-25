#include <iostream>

#include <memory>
#include <vector>

#define STB_IMAGE_IMPLEMENTATION
#include "stb/stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb/stb_image_write.h"

#include "abcd.cuh"
#include "cuda_common.cuh"

constexpr int RADIUS = 7;

__global__ void img_blur(unsigned char* img_data, unsigned char* out_data, int w, int h, int n)
{
    int col = blockDim.x * blockIdx.x + threadIdx.x;
    int row = blockDim.y * blockIdx.y + threadIdx.y;
    int linearized_offset = row * w + col;

    if(col < w && row < h)
    {
        int pixVal_r = 0;
        int pixVal_g = 0;
        int pixVal_b = 0;
        int pixVal_a = 0;
        int pixelsCount = 0;
        for(int r = -RADIUS; r <= RADIUS; r++)
        {
            for(int c = -RADIUS; c <= RADIUS; c++)
            {
                int currRow = r + row;
                int currCol = c + col;
                if(currRow >= 0 && currRow < h &&
                    currCol >= 0 && currCol < w)
                {
                    int rgbOffset = (currRow * w + currCol) * n;
                    pixVal_r += img_data[rgbOffset];
                    pixVal_g += img_data[rgbOffset + 1];
                    pixVal_b += img_data[rgbOffset + 2];
                    if(n > 3)
                    {
                        pixVal_a += img_data[rgbOffset + 3];
                    }
                    ++pixelsCount;
                }
            }
        }
        out_data[linearized_offset * n] = (unsigned char)((float)pixVal_r / pixelsCount);
        out_data[linearized_offset * n + 1] = (unsigned char)((float)pixVal_g / pixelsCount);
        out_data[linearized_offset * n + 2] = (unsigned char)((float)pixVal_b / pixelsCount);
        if(n > 3){
            out_data[linearized_offset * n + 3] = (unsigned char)((float)pixVal_a / pixelsCount);
        }
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
    cudaPtr<unsigned char> out_img_d = make_cuda_unique<unsigned char>(img_size_bytes);

    CUDA_CHECK(cudaMemcpy(img_data_d.get(), img_data, img_size_bytes, cudaMemcpyHostToDevice));

    const int TILE_X = 16;
    const int TILE_Y = 16;
    dim3 tpb(TILE_X, TILE_Y, 1);
    dim3 blockSize(
        (img_w + TILE_X - 1) / TILE_X,
        (img_h + TILE_Y - 1) / TILE_Y,
        1
    );

    img_blur<<<blockSize, tpb>>>(img_data_d.get(), out_img_d.get(), img_w, img_h, n);
    CUDA_KERNEL_CHECK();

    std::vector<unsigned char> out_h(img_size_bytes);
    CUDA_CHECK(cudaMemcpy(out_h.data(), out_img_d.get(), img_size_bytes, cudaMemcpyDeviceToHost));

    if(!stbi_write_png("newImg.png", img_w, img_h, n, (void*)out_h.data(), img_w * n))
    {
        std::cout << "stbi_write_png failure\n";
    }

    stbi_image_free(img_data);
}
