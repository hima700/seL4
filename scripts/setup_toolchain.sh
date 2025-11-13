#!/bin/bash
#
# Setup ARM64 toolchain for Microkit builds
# Downloads and extracts ARM GNU toolchain if not already present
#

set -e

TOOLCHAIN_DIR="$HOME/.local/arm-toolchain"
TOOLCHAIN_BIN="$TOOLCHAIN_DIR/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf/bin"

if [ ! -f "$TOOLCHAIN_BIN/aarch64-none-elf-gcc" ]; then
    echo "Toolchain not found. Downloading ARM GNU toolchain..."
    mkdir -p "$TOOLCHAIN_DIR"
    cd "$TOOLCHAIN_DIR"
    
    if [ ! -f toolchain.tar.xz ]; then
        curl -L https://developer.arm.com/-/media/Files/downloads/gnu/13.2.rel1/binrel/arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-elf.tar.xz -o toolchain.tar.xz
    fi
    
    echo "Extracting toolchain..."
    tar -xf toolchain.tar.xz
    
    echo "Toolchain extracted to $TOOLCHAIN_DIR"
fi

export PATH="$TOOLCHAIN_BIN:$PATH"
echo "Toolchain added to PATH: $TOOLCHAIN_BIN"
echo "Verifying installation..."
aarch64-none-elf-gcc --version | head -1

