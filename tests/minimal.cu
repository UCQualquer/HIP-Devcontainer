// nvcc minimal.cu -o minimal && ./minimal
#include <iostream>
#include <cmath>

__global__ void add(int n, const float* x, float* y) {
    for (int i = 0; i < n; i++)
        y[i] = x[i] + y[i];
}

int main(void) {
    int count = 1 << 20;
    float *x;
    float *y;

    cudaMallocManaged(&x, count * sizeof(float));
    cudaMallocManaged(&y, count * sizeof(float));

    for (int i = 0; i < count; i++) {
        x[i] = 1.0F;
        y[i] = 2.0F;
    }

    add<<<8, 8>>>(count, x, y);

    cudaDeviceSynchronize();

    float maxError = 0.0F;
    for (int i = 0; i < count; i++) {
        maxError = fmax(maxError, fabs(y[i] - 3.0F));
    }
    std::cout << "Max error: " << maxError << "\n";

    cudaFree(x);
    cudaFree(y);
    return 0;
}