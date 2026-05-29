FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential git wget unzip xz-utils zip \
    openjdk-11-jdk python3 python3-pip ccache \
    && rm -rf /var/lib/apt/lists/*

# Setup ccache
RUN mkdir -p ~/.ccache && \
    echo "compression = true" >> ~/.ccache/ccache.conf

WORKDIR /project

# Copy source
COPY . /project

# Build script
RUN echo '#!/bin/bash' > /build.sh && \
    echo 'set -e' >> /build.sh && \
    echo 'BUILD_TYPE=${1:-release}' >> /build.sh && \
    echo 'cd /project/build' >> /build.sh && \
    echo 'mkdir -p Android_Qt_5_15_2_Clang_Multi_Abi-Release' >> /build.sh && \
    echo 'cd Android_Qt_5_15_2_Clang_Multi_Abi-Release' >> /build.sh && \
    echo 'qmake -r /project/qgroundcontrol.pro -spec android-clang CONFIG+=installer CONFIG+=$BUILD_TYPE ANDROID_ABIS="arm64-v8a;armeabi-v7a"' >> /build.sh && \
    echo 'make -j$(nproc)' >> /build.sh && \
    chmod +x /build.sh

# Default: build release
CMD ["/build.sh", "release"]
