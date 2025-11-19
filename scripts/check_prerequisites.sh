#!/bin/bash
#
# Check prerequisites for running seL4 Microkit applications
#

set -e

export PATH="/usr/bin:/bin:/usr/local/bin:$PATH"

echo "Checking prerequisites for seL4 Microkit project..."
echo ""

MISSING=0

# Check QEMU
QEMU_FOUND=0
if command -v qemu-system-aarch64 > /dev/null 2>&1; then
    QEMU_PATH=$(which qemu-system-aarch64)
    if [ -f "$QEMU_PATH" ] && [ -x "$QEMU_PATH" ]; then
        echo "✓ QEMU: $QEMU_PATH"
        qemu-system-aarch64 --version 2>&1 | head -1 || echo "  Warning: QEMU found but version check failed"
        QEMU_FOUND=1
    fi
fi

if [ $QEMU_FOUND -eq 0 ]; then
    # Try to find it in common locations
    if [ -f "/usr/bin/qemu-system-aarch64" ] && [ -x "/usr/bin/qemu-system-aarch64" ]; then
        echo "✓ QEMU: /usr/bin/qemu-system-aarch64 (found but not in PATH)"
        QEMU_FOUND=1
    else
        echo "✗ QEMU: Not found"
        echo "  Install with: sudo apt update && sudo apt install -y qemu-system-arm qemu-system-misc"
        MISSING=1
    fi
fi
echo ""

# Check ARM toolchain
if command -v aarch64-none-elf-gcc > /dev/null 2>&1; then
    echo "✓ ARM Toolchain: $(which aarch64-none-elf-gcc)"
    aarch64-none-elf-gcc --version | head -1
else
    TOOLCHAIN_BIN="$HOME/.local/arm-toolchain/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf/bin"
    if [ -f "$TOOLCHAIN_BIN/aarch64-none-elf-gcc" ]; then
        echo "✓ ARM Toolchain: Found at $TOOLCHAIN_BIN (not in PATH)"
        echo "  Run: ./scripts/setup_toolchain.sh"
    else
        echo "✗ ARM Toolchain: Not found"
        echo "  Run: ./scripts/setup_toolchain.sh"
        MISSING=1
    fi
fi
echo ""

# Check Python/matplotlib (optional for metrics)
if command -v python3 > /dev/null 2>&1; then
    if python3 -c "import matplotlib" 2>/dev/null; then
        echo "✓ Python/matplotlib: Available for plotting"
    else
        echo "⚠ Python/matplotlib: Not available (optional for metrics plotting)"
        echo "  Install with: pip3 install matplotlib numpy"
    fi
else
    echo "⚠ Python3: Not found (optional for metrics plotting)"
fi
echo ""

# Check bc (optional for comparison)
if command -v bc > /dev/null 2>&1; then
    echo "✓ bc: Available for metrics comparison"
else
    echo "⚠ bc: Not found (optional for metrics comparison)"
    echo "  Install with: sudo apt install bc"
fi
echo ""

if [ $MISSING -eq 0 ]; then
    echo "All required prerequisites are met!"
    exit 0
else
    echo "Some required prerequisites are missing. Please install them and try again."
    exit 1
fi

