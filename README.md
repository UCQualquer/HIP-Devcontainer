# HIP Devcontainer
Sample [Devcontainer](https://code.visualstudio.com/docs/devcontainers/containers) setup for development of C++ applications that use [AMD's HIP sdk](https://archive.is/oqy3A) and target the CUDA runtime.

This is a Devcontainer setup for those who want to develop applications compiled with HIP targeting CUDA. I don't have an AMD gpu to try setting up an environment targeting ROCm, so CUDA is the best I can do. This sample is copied from a personal project, so settings and installed extensions and libraries are my personal choice.

Although Debian 13 is supported since CUDA 13.1.0, I haven't had the willpower to update the base image to Debian 13.

This devcontainer inclues:
* CMake + Ninja generator
* Clang compiler and other LLVM tooling (lld, lldb, clang-tidy, clangd, clang-format, etc)
* hipcc compiler and base HIP headers and libraries.
* nvcc compiler, compute-sanitizer tool and base CUDA headers and libraries.
* VSCode extensions for development of projects with C++ and CMake.
* lldb debugger connector and profile.

On the Dockerfile file, you will see some configurable parameters. ROCM_VERSION has been tested to install correctly from somewhere around version 6.4.2 up to 7.2.4 (version 7.14 changes how things are installed, but the HIP compiler is not yet available on this version, only the ROCm libraries). The CUDA Toolkit version has been tested to install correctly from 12.9 to 13.3. You can tweak these parameters to your liking but I don't know what could break from doing that. The only installed libraries from HIP/CUDA are the ones I needed, so libraries like cublas and other math things are not installed, only the bare minimum. Some environment variables expected by things like CMake are set (last lines of the Dockerfile).

Again, this is mostly aimed at targeting CUDA, so drivers for AMD gpus and whatever else is required to target ROCm is not installed.

This image has a size of ~5GB after build, which is very small when taking into account how big the complete HIP and CUDA sdks are when everything is installed. The instructions on the Dockerfile are NOT set in a way to be cache-friendly, but the default parameters there allow it to build quite quickly, so it is not a big issue (for me). Most parameters and weird things are documented on the Dockerfile itself.

The repository includes two test files you can use to check that a minimal application with CUDA/HIP can build on the devcontainer environment. The command line to build them is at the top of their files.

Now, the process of integrating HIP and CUDA with CMake is a process akin to witchcraft, and although I have done it after much hair loss, I haven't included it on this repository.
