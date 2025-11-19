#!/bin/bash
#
# Run script for seL4 Microkit applications in QEMU
# Usage: ./run.sh [app_name] [board] [config]
#

set -e

# Ensure basic PATH includes standard locations
export PATH="/usr/bin:/bin:/usr/local/bin:/usr/sbin:$PATH"

# Find QEMU - try multiple methods
QEMU_BIN=""

# Debug: check if file exists
if [ -f "/usr/bin/qemu-system-aarch64" ]; then
    if [ -x "/usr/bin/qemu-system-aarch64" ]; then
        QEMU_BIN="/usr/bin/qemu-system-aarch64"
    else
        echo "Warning: /usr/bin/qemu-system-aarch64 exists but is not executable"
        chmod +x /usr/bin/qemu-system-aarch64 2>/dev/null || true
        if [ -x "/usr/bin/qemu-system-aarch64" ]; then
            QEMU_BIN="/usr/bin/qemu-system-aarch64"
        fi
    fi
fi

# Fallback to command lookup
if [ -z "$QEMU_BIN" ]; then
    if command -v qemu-system-aarch64 > /dev/null 2>&1; then
        QEMU_BIN=$(command -v qemu-system-aarch64)
    fi
fi

# Final check
if [ -z "$QEMU_BIN" ]; then
    echo "Error: qemu-system-aarch64 not found"
    echo "Please install QEMU: sudo apt install qemu-system-arm qemu-system-misc"
    echo "Checking /usr/bin/qemu-system-aarch64:"
    ls -la /usr/bin/qemu-system-aarch64 2>&1 || echo "File does not exist"
    exit 1
fi

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
        "$QEMU_BIN" -machine virt,virtualization=on,gic-version=2 \
            -cpu cortex-a53 \
            -nographic \
            -serial mon:stdio \
            -m 2048M \
            -kernel "$IMAGE_FILE" \
            -no-reboot
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

