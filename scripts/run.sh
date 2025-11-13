#!/bin/bash
#
# Run script for seL4 Microkit applications in QEMU
# Usage: ./run.sh [app_name] [board] [config]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

APP_NAME="${1:-hello_world}"
BOARD="${2:-qemu_virt_aarch64}"
CONFIG="${3:-debug}"

BUILD_DIR="$PROJECT_ROOT/out/$APP_NAME-$BOARD-$CONFIG"
IMAGE_FILE="$BUILD_DIR/loader.img"

if [ ! -f "$IMAGE_FILE" ]; then
    echo "Error: Image file not found: $IMAGE_FILE"
    echo "Please build first using: ./build.sh $APP_NAME $BOARD $CONFIG"
    exit 1
fi

echo "Running $APP_NAME on $BOARD"
echo "Image: $IMAGE_FILE"
echo "Press Ctrl+A then X to exit QEMU"
echo ""

case "$BOARD" in
    qemu_virt_aarch64)
        qemu-system-aarch64 -machine virt,virtualization=on \
            -cpu cortex-a72 \
            -nographic \
            -serial mon:stdio \
            -m size=1024M \
            -kernel "$IMAGE_FILE"
        ;;
    qemu_virt_riscv64)
        qemu-system-riscv64 -machine virt \
            -cpu rv64 \
            -nographic \
            -serial mon:stdio \
            -m size=1024M \
            -kernel "$IMAGE_FILE"
        ;;
    *)
        echo "Error: Unsupported board: $BOARD"
        echo "Supported boards: qemu_virt_aarch64, qemu_virt_riscv64"
        exit 1
        ;;
esac

