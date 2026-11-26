#include <iostream>
#include <vector>
#include <random>

#include "abcd.cuh"
#include "cuda_common.cuh"

constexpr int WIDTH = 2;
constexpr int HEIGHT = 2;
constexpr int SIZE = WIDTH * HEIGHT;

__global__ void mat_mul_1out(const float* M, const float* N, float* out, int width, int height)
{
   int col = blockDim.x * blockIdx.x + threadIdx.x;
   int row = blockDim.y * blockIdx.y + threadIdx.y;
   if((col < width) && (row < height))
   {
       float val = 0;
       // it only works for square matrix
       for(int k = 0; k < width; k++)
       {
           val += M[row * width + k] * N[k * width + col];
       }
       out[row * width + col] = val;
   }
}

__global__ void mat_mul_1row(const float* M, const float* N, float* out, int width, int height)
{
   int col = blockDim.x * blockIdx.x + threadIdx.x;
   int row = blockDim.y * blockIdx.y + threadIdx.y;
   if((col < width) && (row < height))
   {
        for(int c = 0; c < width; c++)
        {
            float val = 0;
            // it only works for square matrix
            for(int k = 0; k < width; k++)
            {
                val += M[row * width + k] * N[k * width + c];
            }
            out[row * width + c] = val;
        }
   }
}

__global__ void mat_mul_1col(const float* M, const float* N, float* out, int width, int height)
{
   int col = blockDim.x * blockIdx.x + threadIdx.x;
   int row = blockDim.y * blockIdx.y + threadIdx.y;
   if((col < width) && (row < height))
   {
       for(int r = 0; r < width; r++)
       {
           float val = 0;
           // it only works for square matrix
           for(int k = 0; k < width; k++)
           {
               val += M[r * width + k] * N[k * width + col];
           }
           out[r * width + col] = val;
       }
   }
}

__global__ void mat_mul_vec(const float* M, const float* vec, float* out, int N)
{
   int col = blockDim.x * blockIdx.x + threadIdx.x;
   int row = blockDim.y * blockIdx.y + threadIdx.y;
   if((col < N) && (row < N))
   {
        float val = 0;
        for(int k = 0; k < N; k++)
        {
            val += M[row * N + k] * vec[k];
        }
        out[row] = val;
   }
}

int main()
{
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_real_distribution<float> dist(0.0f, 10.0f);

    std::vector<float> M_H(SIZE);
    std::vector<float> N_H(SIZE);
    std::vector<float> vec_h(SIZE);

    for(int i = 0 ; i < SIZE; i++)
    {
        M_H[i] = dist(gen);
        N_H[i] = dist(gen);
        vec_h[i] = dist(gen);
    }

    std::cout << "========= M ====== \n";
    for(int j = 0 ; j < SIZE; j++)
    {
        if(j != 0 && j % WIDTH == 0)
            std::cout << "\n";

        std::cout << M_H[j] << " ";
    }
    std::cout << std::endl;

    std::cout << "========= N ====== \n";
    for(int j = 0 ; j < SIZE; j++)
    {
        if(j != 0 && j % WIDTH == 0)
            std::cout << "\n";

        std::cout << N_H[j] << " ";
    }
    std::cout << std::endl;

    std::cout << "========= vec ====== \n";
    for(int j = 0 ; j < WIDTH; j++)
    {
        if(j % WIDTH == 0)
            std::cout << "\n";

        std::cout << vec_h[j] << " ";
    }
    std::cout << std::endl;

    cudaPtr<float> M_d = make_cuda_unique<float>(SIZE);
    cudaPtr<float> N_d = make_cuda_unique<float>(SIZE);
    cudaPtr<float> out_d = make_cuda_unique<float>(SIZE);
    cudaPtr<float> out_d_1r = make_cuda_unique<float>(SIZE);
    cudaPtr<float> out_d_1c = make_cuda_unique<float>(SIZE);
    cudaPtr<float> out_vec_d = make_cuda_unique<float>(WIDTH);

    CUDA_CHECK(cudaMemcpy(M_d.get(), M_H.data(), SIZE * sizeof(float), cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(N_d.get(), N_H.data(), SIZE * sizeof(float) , cudaMemcpyHostToDevice));

    dim3 tpb(16,16,1);
    dim3 blockSize(
        (WIDTH + tpb.x - 1) / tpb.x,
        (HEIGHT + tpb.y - 1) / tpb.y,
        1
    );
    mat_mul_1out<<<blockSize, tpb>>>(M_d.get(), N_d.get(), out_d.get(), WIDTH, HEIGHT);
    CUDA_KERNEL_CHECK();

    std::vector<float> out_h(SIZE);
    CUDA_CHECK(cudaMemcpy(out_h.data(), out_d.get(), SIZE * sizeof(float), cudaMemcpyDeviceToHost));

    std::cout << "res: 1o";
    for(int j = 0 ; j < SIZE; j++)
    {
        if(j % WIDTH == 0)
            std::cout << "\n";

        std::cout << out_h[j] << " ";
    }
    std::cout << std::endl;

    mat_mul_1row<<<blockSize, tpb>>>(M_d.get(), N_d.get(), out_d_1r.get(), WIDTH, HEIGHT);
    CUDA_KERNEL_CHECK();

    std::vector<float> out_h_1r(SIZE);
    CUDA_CHECK(cudaMemcpy(out_h_1r.data(), out_d_1r.get(), SIZE * sizeof(float), cudaMemcpyDeviceToHost));

    std::cout << "res: 1r";
    for(int j = 0 ; j < SIZE; j++)
    {
        if(j % WIDTH == 0)
            std::cout << "\n";

        std::cout << out_h_1r[j] << " ";
    }
    std::cout << std::endl;

    mat_mul_1col<<<blockSize, tpb>>>(M_d.get(), N_d.get(), out_d_1c.get(), WIDTH, HEIGHT);
    CUDA_KERNEL_CHECK();

    std::vector<float> out_h_1c(SIZE);
    CUDA_CHECK(cudaMemcpy(out_h_1c.data(), out_d_1c.get(), SIZE * sizeof(float), cudaMemcpyDeviceToHost));

    std::cout << "res: 1c";
    for(int j = 0 ; j < SIZE; j++)
    {
        if(j % WIDTH == 0)
            std::cout << "\n";

        std::cout << out_h_1c[j] << " ";
    }
    std::cout << std::endl;

    mat_mul_vec<<<blockSize, tpb>>>(M_d.get(), vec_h.data(), out_vec_d.get(), WIDTH);
    CUDA_KERNEL_CHECK();

    std::vector<float> vec_out_h(WIDTH);
    CUDA_CHECK(cudaMemcpy(vec_out_h.data(), out_vec_d.get(), WIDTH * sizeof(float), cudaMemcpyDeviceToHost));

    std::cout << "res: vec";
    for(int j = 0 ; j < WIDTH; j++)
    {
        if(j % WIDTH == 0)
            std::cout << "\n";

        std::cout << vec_out_h[j] << " ";
    }
    std::cout << std::endl;
}
