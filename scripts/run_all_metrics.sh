#!/bin/bash
#
# One-command metrics runner: Build, run, measure, plot, and archive
# Usage: ./run_all_metrics.sh [iterations]
#

set -e

export PATH="/usr/bin:/bin:/usr/local/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ITERATIONS="${1:-10}"

echo "=========================================="
echo "Complete Metrics Collection Pipeline"
echo "=========================================="
echo "Iterations: $ITERATIONS"
echo ""

# Step 0: Check prerequisites
echo ""
echo "Step 0: Checking prerequisites..."
if ! command -v qemu-system-aarch64 > /dev/null 2>&1; then
    echo "ERROR: qemu-system-aarch64 not found!"
    echo "Please install QEMU:"
    echo "  sudo apt update"
    echo "  sudo apt install qemu-system-arm qemu-system-misc"
    exit 1
fi
echo "QEMU found: $(which qemu-system-aarch64)"

# Step 1: Build Linux baseline
echo ""
echo "Step 1: Building Linux baseline..."
cd "$PROJECT_ROOT/linux_baseline"
make clean > /dev/null 2>&1 || true
make
cd "$PROJECT_ROOT"

# Step 2: Setup toolchain if needed
echo ""
echo "Step 2: Setting up ARM toolchain..."
TOOLCHAIN_DIR="$HOME/.local/arm-toolchain"
TOOLCHAIN_BIN="$TOOLCHAIN_DIR/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf/bin"

if ! command -v aarch64-none-elf-gcc > /dev/null 2>&1; then
    if [ ! -f "$TOOLCHAIN_BIN/aarch64-none-elf-gcc" ]; then
        echo "Toolchain not found, running setup..."
        if "$SCRIPT_DIR/setup_toolchain.sh"; then
            echo "Toolchain setup successful"
        else
            echo "ERROR: Toolchain setup failed!"
            echo "Please run manually: ./scripts/setup_toolchain.sh"
            exit 1
        fi
    fi
    
    # Add toolchain to PATH for this script
    if [ -f "$TOOLCHAIN_BIN/aarch64-none-elf-gcc" ]; then
        export PATH="$TOOLCHAIN_BIN:$PATH"
        echo "Toolchain added to PATH: $TOOLCHAIN_BIN"
    else
        echo "ERROR: Toolchain binary not found at $TOOLCHAIN_BIN"
        echo "Please run: ./scripts/setup_toolchain.sh"
        exit 1
    fi
else
    echo "Toolchain already in PATH"
fi

# Step 3: Build seL4 applications
echo ""
echo "Step 3: Building seL4 IPC demo..."
"$SCRIPT_DIR/build.sh" ipc_demo qemu_virt_aarch64 debug

echo ""
echo "Step 3b: Building hello_world baseline..."
"$SCRIPT_DIR/build.sh" hello_world qemu_virt_aarch64 debug

# Step 4: Run Linux metrics
echo ""
echo "Step 4: Running Linux metrics..."
# Create a temporary directory for metrics
TIMESTAMP=$(date +%Y%m%d-%H%M)
METRICS_DIR="$PROJECT_ROOT/out/metrics/$TIMESTAMP"
mkdir -p "$METRICS_DIR"

LINUX_LOG="$METRICS_DIR/linux_run.log"
LINUX_CSV="$METRICS_DIR/linux_results.csv"

"$SCRIPT_DIR/run_linux.sh" "$ITERATIONS" > "$LINUX_LOG" 2>&1

# Parse Linux metrics
echo "iteration,latency_ns,timestamp" > "$LINUX_CSV"
grep "CLIENT|METRIC: Total IPC latency=" "$LINUX_LOG" | \
    sed -E 's/.*latency=([0-9]+) ns.*/\1/' | \
    awk '{print NR "," $1 "," systime()}' >> "$LINUX_CSV"

echo "Linux metrics saved to $LINUX_CSV"

# Step 5: Run seL4 metrics
echo ""
echo "Step 5: Running seL4 metrics..."
# We want seL4 results in the same directory
# run_metrics.sh creates its own timestamped directory, we should probably guide it or move files
# For now, let it run and we'll find the latest one
"$SCRIPT_DIR/run_metrics.sh" ipc_demo qemu_virt_aarch64 debug "$ITERATIONS"

# Find the seL4 results (it creates a new timestamped dir)
# Latest metrics directory (strip trailing slash)
SEL4_RUN_DIR=$(ls -td "$PROJECT_ROOT/out/metrics"/*/ 2>/dev/null | head -1)
SEL4_RUN_DIR="${SEL4_RUN_DIR%/}"
if [ "$SEL4_RUN_DIR" == "$METRICS_DIR" ]; then
    :
else
    # Move Linux results to the final directory so everything is together
    if [ "$LINUX_CSV" != "$SEL4_RUN_DIR/linux_results.csv" ]; then
        cp "$LINUX_CSV" "$SEL4_RUN_DIR/linux_results.csv"
    fi
    if [ "$LINUX_LOG" != "$SEL4_RUN_DIR/linux_run.log" ]; then
        cp "$LINUX_LOG" "$SEL4_RUN_DIR/linux_run.log"
    fi
    METRICS_DIR="$SEL4_RUN_DIR"
fi
# Update timestamp to final metrics dir
TIMESTAMP=$(basename "$METRICS_DIR")

# Step 6: Archive results
echo ""
echo "Step 6: Archiving results..."
"$SCRIPT_DIR/archive_results.sh" "$TIMESTAMP"

# Step 7: Generate plots (if Python/matplotlib available)
echo ""
echo "Step 7: Generating plots..."
SEL4_CSV="$METRICS_DIR/results.csv"
LINUX_CSV_FINAL="$METRICS_DIR/linux_results.csv"
PLOT_FILE="$METRICS_DIR/metrics_plot.png"

if command -v python3 > /dev/null && python3 -c "import matplotlib" 2>/dev/null; then
    if [ -f "$SEL4_CSV" ] && [ -s "$SEL4_CSV" ]; then
        if [ -f "$LINUX_CSV_FINAL" ] && [ -s "$LINUX_CSV_FINAL" ]; then
            python3 "$SCRIPT_DIR/plot_metrics.py" "$SEL4_CSV" "$LINUX_CSV_FINAL" "$PLOT_FILE"
        else
            python3 "$SCRIPT_DIR/plot_metrics.py" "$SEL4_CSV" "" "$PLOT_FILE"
        fi
        echo "Plot saved to: $PLOT_FILE"
    else
        echo "seL4 CSV file is empty or missing, skipping plot generation"
    fi
else
    echo "Python3/matplotlib not available, skipping plots"
    echo "Install with: pip3 install matplotlib numpy"
fi

echo ""
echo "=========================================="
echo "Metrics collection complete!"
echo "Results archived to: out/$TIMESTAMP/"
echo "=========================================="

