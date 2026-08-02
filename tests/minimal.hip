// HIP_PLATFORM=nvidia hipcc minimal.hip -x cu -o minimal && ./minimal
#include <iostream>
#include <cmath>

#include <hip/hip_runtime.h>

__global__ void add(int n, const float* x, float* y) {
    for (int i = 0; i < n; i++)
        y[i] = x[i] + y[i];
}

int main(void) {
    int count = 1 << 20;
    float *x;
    float *y;

    hipMallocManaged(&x, count * sizeof(float));
    hipMallocManaged(&y, count * sizeof(float));

    for (int i = 0; i < count; i++) {
        x[i] = 1.0F;
        y[i] = 2.0F;
    }

    add<<<8, 8>>>(count, x, y);

    hipDeviceSynchronize();

    float maxError = 0.0F;
    for (int i = 0; i < count; i++) {
        maxError = fmax(maxError, fabs(y[i] - 3.0F));
    }
    std::cout << "Max error: " << maxError << "\n";

    hipFree(x);
    hipFree(y);
    return 0;
}