FROM debian:12-slim
ARG DEBIAN_FRONTEND=noninteractive

# Set this to 1 to build LLVM/Clang from source. Doing so may take hours.
# This is useful to choose exactly what parts of LLVM to build, so to save
# disk space.
ARG LLVM_FROM_SOURCE=0
# Any version at https://github.com/llvm/llvm-project/releases, or
# any version tag when building from source.
ARG LLVM_VERSION=22.1.8
# Set this to 1 to use the pre-built binaries available on LLVM's Github releases
# page. These are quite big, +10gb. Setting this to 0 instead will register
# their APT repository and install them through apt-get. This is less disk-hungry
# but doesn't let you choose minor versions like 22.x.x, only the 22 major.
ARG LVVM_FROM_TARBALL=0
# Set this to 1 to build CMake from source. Does not take too long but it's still
# faster to just download the pre-built binaries
ARG CMAKE_FROM_SOURCE=0
# Any version at https://github.com/Kitware/CMake/releases, or
# any version tag when bulding from source.
ARG CMAKE_VERSION=4.4.1
# Set this to 1 to build Ninja from source. Does not take too long but it's still
# faster to just download the pre-built binaries
ARG NINJA_FROM_SOURCE=0
# Any version at https://github.com/ninja-build/ninja/releases, or
# any version tag when bulding from source.
ARG NINJA_VERSION=1.13.2

# We don't build these two from source, but we still try to only install the
# minimal packages from them.
ARG CUDA_TOOLKIT_VERSION=13.3
ARG ROCM_VERSION=7.2.4

# Install dependencies for the next steps or generally
# good to have on a development environment
RUN set -eu; \
    mkdir /temp; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        git \
        g++ \
        make \
        wget \
        libssl-dev \
        ca-certificates \
        python3;

# Download & build CMake.
RUN set -eu; \
    cd /temp; \
    if [ "${CMAKE_FROM_SOURCE}" -eq "1" ]; then \
        # https://gitlab.kitware.com/cmake/cmake/-/blob/3b5342b305d81f75406cf82da0c63f9361b33e02/README.rst
        # https://askubuntu.com/a/865294
        echo "Installing CMake ${CMAKE_VERSION}."; \
        git clone -c advice.detachedHead=false --branch v${CMAKE_VERSION} --single-branch --depth=1 https://gitlab.kitware.com/cmake/cmake.git; \
        cd cmake; \
        ./bootstrap --parallel=$(nproc) > /dev/null; \
        make -j$(nproc) > /dev/null; \
        make install > /dev/null; \
        cd /temp; \
        rm -rf cmake; \
    else \
        echo "Installing pre-built CMake ${CMAKE_VERSION}."; \
        wget -q -O - https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz \
            | tar -xz --strip-components 1 -C /usr/local; \
    fi;

# Download & build Ninja generator.
RUN set -eu; \
    cd /temp; \
    if [ "${NINJA_FROM_SOURCE}" -eq "1" ]; then \
        # https://github.com/ninja-build/ninja/tree/b90f3587711b2171d2dafa8179fe013475558e8d?tab=readme-ov-file#cmake
        echo "Installing Ninja generator ${NINJA_VERSION}."; \
        git clone -c advice.detachedHead=false --branch v${NINJA_VERSION} --single-branch --depth=1 https://github.com/ninja-build/ninja.git; \
        cd ninja; \
        cmake -Bbuild-cmake -DBUILD_TESTING=OFF -DCMAKE_MESSAGE_LOG_LEVEL=WARNING -DCMAKE_RULE_MESSAGES=OFF; \
        cmake --build build-cmake; \
        ## Make it available to PATH
        echo "Making Ninja available globally."; \
        cp build-cmake/ninja /usr/local/bin/; \
    else \
        # https://github.com/ninja-build/ninja/releases
        echo "Installing pre-built Ninja generator ${NINJA_VERSION}."; \
        apt-get install -y -q --no-install-recommends unzip; \
        wget -q https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}/ninja-linux.zip; \
        unzip ninja-linux.zip -d /usr/local/bin/; \
        apt-get remove -y --auto-remove --purge unzip; \
        rm -f ninja-linux.zip; \
    fi;

# Download & build Clang.
RUN set -eu; \
    cd /temp; \
    if [ "${LLVM_FROM_SOURCE}" -eq "1" ]; then \
        # https://llvm.org/docs/GettingStarted.html#getting-the-source-code-and-building-llvm
        # https://llvm.org/docs/CMake.html
        # https://mooseframework.inl.gov/getting_started/installation/manual_installation_llvm.html
        echo "Installing Clang ${LLVM_VERSION}. This may take hours..."; \
        git clone -c advice.detachedHead=false --branch llvmorg-${LLVM_VERSION} --single-branch --depth=1 https://github.com/llvm/llvm-project.git; \
        cd llvm-project; \
        mkdir build; \
        cd build; \
        cmake ../llvm \
            -G Ninja \
            -DCMAKE_BUILD_TYPE=Release \
            -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra" \
            -DLLVM_INCLUDE_TESTS=OFF \
            -DLLVM_INCLUDE_EXAMPLES=OFF \
            -DLLVM_INCLUDE_BENCHMARKS=OFF; \
        ninja; \
        ninja install; \
        cd /temp; \
        rm -rf llvm-project; \
    elif [ "${LVVM_FROM_TARBALL}" -eq "1" ]; then \
        echo "Installing pre-built Clang ${LLVM_VERSION} from release tarball."; \
        apt-get install -y --no-install-recommends xz-utils; \
        wget -q -O - https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/LLVM-${LLVM_VERSION}-Linux-X64.tar.xz \
            | tar -xJ --strip-components 1 -C /usr/local; \
        apt-get remove -y --auto-remove --purge xz-utils; \
    else \
        # https://apt.llvm.org/
        echo "Installing pre-built Clang ${LLVM_VERSION} from apt repository."; \
        echo "Note that installing Clang this way means choosing either 22.x.x or 22.y.y"; \
        echo "will install the same 22 version. Your only choice is between major versions."; \
        LLVM_MAJOR_VERSION=$(echo "${LLVM_VERSION}" | sed "s|\.[0-9]\+\.[0-9]\+||"); \
        apt-get install -y --no-install-recommends gnupg; \
        wget -q -O - https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc; \
        echo "deb https://apt.llvm.org/bookworm/ llvm-toolchain-bookworm-$LLVM_MAJOR_VERSION main" > /etc/apt/sources.list.d/apt.llvm.org.list; \
        apt-get update; \
        apt-get install -y --no-install-recommends \
            clang-$LLVM_MAJOR_VERSION \
            clangd-$LLVM_MAJOR_VERSION \
            lld-$LLVM_MAJOR_VERSION \
            lldb-$LLVM_MAJOR_VERSION \
            clang-tidy-$LLVM_MAJOR_VERSION; \
        # Make executables available with their usual names
        for item in $(ls /usr/bin/*-$LLVM_MAJOR_VERSION); do \
            new_name=$(echo "$item" | sed "s|-[0-9]\+||"); \
            ln -s $item $new_name; \
        done; \
    fi; \
    \
    # Cleanup
    rm -rf /temp/*

# Install HIP thingies (NOT AMD gpu drivers).
# Install before Nvidia thingies because, ultimately, HIP
# is 100% necessary, in any platform.
RUN set -eu; \
    cd /temp; \
    apt-get install -y --no-install-recommends gnupg; \
    _ROCM_VERSION="${ROCM_VERSION}"; \
    # Versions after ROCm 7.2.4 took a new way to install things
    if dpkg --compare-versions "${ROCM_VERSION}" gt 7.2.4; then \
        # https://rocm.docs.amd.com/projects/HIP/en/latest/install/install.html
        # https://rocm.docs.amd.com/en/latest/install/rocm.html
        wget -q -O - https://repo.amd.com/rocm/packages-multi-arch/gpg/rocm.gpg  \
            | gpg --dearmor | tee /etc/apt/keyrings/amdrocm.gpg > /dev/null; \
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/amdrocm.gpg] https://repo.amd.com/rocm/packages-multi-arch/debian12 stable main" \
            | tee /etc/apt/sources.list.d/rocm.list; \
        apt-get update; \
        _ROCM_VERSION=${_ROCM_VERSION%.*}; \
        # HIP is not yet updated to 7.14.0, only 7.2.4, so I'm not sure what errors will pop up
        # when building with this, but these are the minimal packages I could get.
        # This errors with not finding some nvidia_hip_runtime.h file and not finding the clang++
        # it is supposed to ship with (even full install doesn't have it).
        # Also, there is no 7.14.N version to test how the packages will be named, so I'll leave
        # it at that for now.
        apt-get install -y --no-install-recommends \
            amdrocm-runtime-dev$_ROCM_VERSION \
            amdrocm-base$_ROCM_VERSION; \
    else \
        wget -q -O - https://repo.radeon.com/rocm/rocm.gpg.key \
            | gpg --dearmor | tee /etc/apt/keyrings/rocm.gpg > /dev/null; \
        # For some reason, some perfectly good versions like 6.4.0 are actually called 6.4
        # on their apt repository, so this check is just for this kind of edge case.
        if echo "$_ROCM_VERSION" | grep -q "\.0$"; then \
            if ! wget --spider "https://repo.radeon.com/rocm/apt/$_ROCM_VERSION"; then \
                _ROCM_VERSION=${_ROCM_VERSION%.*}; \
            fi \
        fi; \
        # Must replace this `jammy` with something else when updating to a new Debian version. Probably.
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/$_ROCM_VERSION jammy main" \
            | tee /etc/apt/sources.list.d/rocm.list; \
        printf "Package: *\nPin: release o=repo.radeon.com\nPin-Priority: 600\n" | tee /etc/apt/preferences.d/rocm-pin-600; \
        apt-get update; \
        apt-get install -y --no-install-recommends \
            hip-dev; \
    fi;

# Install Nvidia thingies.
# Based on https://gitlab.com/nvidia/container-images/cuda/-/blob/181367a60650bee1a0d32f52b0e96d83d982de0d/dist/12.9.1/ubuntu2204/devel/Dockerfile
RUN set -eu; \
    cd /temp; \
    # Install nvidia drivers (https://wiki.debian.org/NvidiaGraphicsDrivers)
    sed -i '/^Components:/ s/$/ contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources; \
    apt-get update; \
    ## linux-headers-generic is required by dkms to make the driver work. It is also why it is installed separately.
    apt-get install -y --no-install-recommends linux-headers-generic; \
    apt-get install -y --no-install-recommends nvidia-open-kernel-dkms nvidia-driver firmware-misc-nonfree nvidia-smi; \
    \
    # Install CUDA toolkit (https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#debian)
    VERSION_ID=$(sed 's/\..*//' /etc/debian_version); \
    wget -q https://developer.download.nvidia.com/compute/cuda/repos/debian${VERSION_ID}/x86_64/cuda-keyring_1.1-1_all.deb; \
    dpkg -i cuda-keyring_1.1-1_all.deb; \
    apt-get update; \
    _CUDA_TOOLKIT_VERSION=$(echo "${CUDA_TOOLKIT_VERSION}" | sed "s|\.|-|"); \
    ## You could just install cuda-toolkit-$_CUDA_TOOLKIT_VERSION but
    ## the disk usage is on you.
    ## `cuda-nvcc` is obviously required by HIP.
    ## `cuda-profiler-api` is required by HIP for some reason.
    ## `cuda-sanitizer` for the compute-sanitizer tool.
    apt-get install -y -q --no-install-recommends \
        cuda-nvcc-$_CUDA_TOOLKIT_VERSION \
        cuda-profiler-api-$_CUDA_TOOLKIT_VERSION \
        cuda-sanitizer-$_CUDA_TOOLKIT_VERSION; \
    \
    # Cleanup
    rm -rf /temp/*

ENV CUDA_PATH="/usr/local/cuda-${CUDA_TOOLKIT_VERSION}" \
    ROCM_PATH="/opt/rocm"
ENV PATH="$PATH:$CUDA_PATH/bin:$ROCM_PATH/bin" \
    LD_LIBRARY_PATH="${CUDA_PATH}/lib64"

CMD ["sleep", "infinity"]