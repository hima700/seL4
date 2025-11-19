# Optimized Dockerfile for seL4 Microkit project
# Layers up to toolchain installation are cached so rebuilds are fast.

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    wget \
    git \
    python3 \
    python3-pip \
    qemu-system-arm \
    qemu-system-misc \
    bc \
    util-linux \
    && rm -rf /var/lib/apt/lists/*

# Python dependencies for plotting
RUN pip3 install matplotlib numpy

# Install ARM GNU Toolchain (cached layer)
WORKDIR /tmp
RUN wget https://developer.arm.com/-/media/Files/downloads/gnu/13.2.rel1/binrel/arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-elf.tar.xz \
    && tar -xf arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-elf.tar.xz \
    && mv arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf /opt/arm-toolchain \
    && rm arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-elf.tar.xz

ENV PATH="/opt/arm-toolchain/bin:${PATH}"

# Copy project files last to leverage Docker cache
WORKDIR /app
COPY . /app

RUN chmod +x /app/scripts/*.sh

CMD ["./scripts/run_all_metrics.sh", "5"]

