#!/bin/bash
#
# Build script for seL4 Microkit applications
# Usage: ./build.sh [hello_world|ipc_demo|fault_tolerance] [board] [config]
#

set -e

# Ensure basic commands are available
export PATH="/usr/bin:/bin:/usr/local/bin:$PATH"

# Get script directory - handle both sourced and executed cases
# Use a simple approach that works even if dirname is not available
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
# Remove filename, keep directory
SCRIPT_DIR="${SCRIPT_PATH%/*}"
# If script was run from current directory, SCRIPT_DIR might be empty or "."
if [ -z "$SCRIPT_DIR" ] || [ "$SCRIPT_DIR" = "." ] || [ "$SCRIPT_DIR" = "./scripts" ]; then
    SCRIPT_DIR="$(pwd)/scripts"
elif [ ! -d "$SCRIPT_DIR" ]; then
    # Fallback: assume scripts/ is relative to current directory
    SCRIPT_DIR="$(pwd)/scripts"
fi
# Get absolute path
if [ -d "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$SCRIPT_DIR" && pwd)"
fi
PROJECT_ROOT="${SCRIPT_DIR%/*}"
MICROKIT_SDK="$PROJECT_ROOT/microkit-sdk"

# Debug: print paths (comment out for production)
# echo "DEBUG: SCRIPT_DIR=$SCRIPT_DIR" >&2
# echo "DEBUG: PROJECT_ROOT=$PROJECT_ROOT" >&2
# echo "DEBUG: MICROKIT_SDK=$MICROKIT_SDK" >&2

APP_NAME="${1:-hello_world}"
BOARD="${2:-qemu_virt_aarch64}"
CONFIG="${3:-debug}"

if [ ! -d "$MICROKIT_SDK" ]; then
    echo "Error: Microkit SDK not found at $MICROKIT_SDK"
    exit 1
fi

APP_DIR="$PROJECT_ROOT/microkit/$APP_NAME"
BUILD_DIR="$PROJECT_ROOT/out/$APP_NAME-$BOARD-$CONFIG"

if [ ! -d "$APP_DIR" ]; then
    echo "Error: Application directory not found: $APP_DIR"
    exit 1
fi

echo "Building $APP_NAME for board $BOARD with config $CONFIG"
echo "Build directory: $BUILD_DIR"

mkdir -p "$BUILD_DIR"

# Setup toolchain PATH if not already set
if ! command -v aarch64-none-elf-gcc >/dev/null 2>&1; then
    TOOLCHAIN_BIN="$HOME/.local/arm-toolchain/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf/bin"
    if [ -d "$TOOLCHAIN_BIN" ]; then
        export PATH="$TOOLCHAIN_BIN:$PATH"
        echo "Added toolchain to PATH: $TOOLCHAIN_BIN"
    else
        echo "Warning: Toolchain not found. Run scripts/setup_toolchain.sh first"
        echo "Or install manually: sudo apt install gcc-aarch64-linux-gnu"
    fi
fi

cd "$APP_DIR"
make BUILD_DIR="$BUILD_DIR" \
     MICROKIT_SDK="$MICROKIT_SDK" \
     MICROKIT_BOARD="$BOARD" \
     MICROKIT_CONFIG="$CONFIG"

echo "Build complete. Image: $BUILD_DIR/loader.img"

