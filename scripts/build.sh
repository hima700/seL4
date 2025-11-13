#!/bin/bash
#
# Build script for seL4 Microkit applications
# Usage: ./build.sh [hello_world|ipc_demo] [board] [config]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MICROKIT_SDK="$PROJECT_ROOT/microkit-sdk"

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

cd "$APP_DIR"
make BUILD_DIR="$BUILD_DIR" \
     MICROKIT_SDK="$MICROKIT_SDK" \
     MICROKIT_BOARD="$BOARD" \
     MICROKIT_CONFIG="$CONFIG"

echo "Build complete. Image: $BUILD_DIR/loader.img"

