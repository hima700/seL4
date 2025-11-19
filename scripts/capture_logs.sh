#!/bin/bash
#
# Capture logs from QEMU serial output for fault tolerance analysis
# Usage: ./capture_logs.sh [app_name] [board] [config] [output_file]
#

set -e

# Ensure basic PATH includes standard locations
export PATH="/usr/bin:/bin:/usr/local/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

APP_NAME="${1:-fault_tolerance}"
BOARD="${2:-qemu_virt_aarch64}"
CONFIG="${3:-debug}"
OUTPUT_FILE="${4:-$PROJECT_ROOT/out/fault_logs_$(date +%Y%m%d_%H%M%S).txt}"

BUILD_DIR="$PROJECT_ROOT/out/$APP_NAME-$BOARD-$CONFIG"
IMAGE_FILE="$BUILD_DIR/loader.img"

if [ ! -f "$IMAGE_FILE" ]; then
    echo "Error: Image file not found: $IMAGE_FILE"
    echo "Please build first using: ./build.sh $APP_NAME $BOARD $CONFIG"
    exit 1
fi

echo "Capturing logs for $APP_NAME on $BOARD"
echo "Image: $IMAGE_FILE"
echo "Output file: $OUTPUT_FILE"
echo ""
echo "NOTE: Logs are being captured to file AND displayed on screen"
echo "Press Ctrl+A then X to exit QEMU"
echo ""

# Create output directory if it doesn't exist
mkdir -p "$(dirname "$OUTPUT_FILE")"

case "$BOARD" in
    qemu_virt_aarch64)
        # Use mon:stdio for display, and tee to capture to file
        qemu-system-aarch64 -machine virt,virtualization=on,gic-version=2 \
            -cpu cortex-a53 \
            -nographic \
            -serial mon:stdio \
            -m 2048M \
            -kernel "$IMAGE_FILE" \
            -no-reboot 2>&1 | tee "$OUTPUT_FILE"
        ;;
    qemu_virt_riscv64)
        qemu-system-riscv64 -machine virt \
            -cpu rv64 \
            -nographic \
            -serial mon:stdio \
            -m size=1024M \
            -kernel "$IMAGE_FILE" 2>&1 | tee "$OUTPUT_FILE"
        ;;
    *)
        echo "Error: Unsupported board: $BOARD"
        echo "Supported boards: qemu_virt_aarch64, qemu_virt_riscv64"
        exit 1
        ;;
esac

echo ""
echo "Logs captured to: $OUTPUT_FILE"
echo "Analyze fault containment by checking:"
echo "  1. Crasher component fault messages"
echo "  2. Server continues operating after crash"
echo "  3. Logger continues operating after crash"
echo "  4. Client continues operating after crash"

