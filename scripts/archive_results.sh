#!/bin/bash
#
# Archive logs and artefacts under out/YYYYMMDD-HHMM/
# Usage: ./archive_results.sh [timestamp]
#

set -e

export PATH="/usr/bin:/bin:/usr/local/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TIMESTAMP="${1:-$(date +%Y%m%d-%H%M)}"
ARCHIVE_DIR="$PROJECT_ROOT/out/$TIMESTAMP"

mkdir -p "$ARCHIVE_DIR"

echo "Archiving results to: $ARCHIVE_DIR"
echo ""

# Archive build outputs
if [ -d "$PROJECT_ROOT/out/ipc_demo-qemu_virt_aarch64-debug" ]; then
    echo "Archiving seL4 build outputs..."
    cp -r "$PROJECT_ROOT/out/ipc_demo-qemu_virt_aarch64-debug" "$ARCHIVE_DIR/" 2>/dev/null || true
fi

if [ -d "$PROJECT_ROOT/out/hello_world-qemu_virt_aarch64-debug" ]; then
    echo "Archiving hello_world build outputs..."
    cp -r "$PROJECT_ROOT/out/hello_world-qemu_virt_aarch64-debug" "$ARCHIVE_DIR/" 2>/dev/null || true
fi

# Archive fault logs
echo "Archiving fault logs..."
cp "$PROJECT_ROOT/out"/fault_logs_*.txt "$ARCHIVE_DIR/" 2>/dev/null || true

# Archive metrics
if [ -d "$PROJECT_ROOT/out/metrics" ]; then
    echo "Archiving metrics..."
    cp -r "$PROJECT_ROOT/out/metrics" "$ARCHIVE_DIR/" 2>/dev/null || true
fi

# Archive Linux baseline binaries
if [ -d "$PROJECT_ROOT/linux_baseline" ]; then
    echo "Archiving Linux baseline..."
    mkdir -p "$ARCHIVE_DIR/linux_baseline"
    cp -r "$PROJECT_ROOT/linux_baseline"/* "$ARCHIVE_DIR/linux_baseline/" 2>/dev/null || true
fi

# Create summary
SUMMARY_FILE="$ARCHIVE_DIR/summary.txt"
{
    echo "Archive Summary"
    echo "Timestamp: $TIMESTAMP"
    echo "Date: $(date)"
    echo ""
    echo "Contents:"
    ls -lh "$ARCHIVE_DIR" | tail -n +2
} > "$SUMMARY_FILE"

echo "Archive complete: $ARCHIVE_DIR"
echo "Summary: $SUMMARY_FILE"


