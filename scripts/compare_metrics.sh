#!/bin/bash
#
# Compare metrics between seL4 and Linux implementations
# Usage: ./compare_metrics.sh [iterations]
#

set -e

export PATH="/usr/bin:/bin:/usr/local/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ITERATIONS="${1:-10}"

echo "Comparing seL4 vs Linux IPC metrics"
echo "Iterations: $ITERATIONS"
echo ""

# Build Linux baseline if needed
LINUX_DIR="$PROJECT_ROOT/linux_baseline"
if [ ! -f "$LINUX_DIR/client/client" ]; then
    echo "Building Linux baseline..."
    cd "$LINUX_DIR"
    make
    cd "$PROJECT_ROOT"
fi

# Run Linux baseline
echo "Running Linux baseline..."
LINUX_OUTPUT=$(mktemp)
"$SCRIPT_DIR/run_linux.sh" "$ITERATIONS" > "$LINUX_OUTPUT" 2>&1

# Extract Linux metrics
LINUX_AVG=$(grep "CLIENT|METRIC: Average latency:" "$LINUX_OUTPUT" | grep -oE "[0-9]+" | head -1 || echo "0")
LINUX_MIN=$(grep "CLIENT|METRIC: Min latency:" "$LINUX_OUTPUT" | grep -oE "[0-9]+" | head -1 || echo "0")
LINUX_MAX=$(grep "CLIENT|METRIC: Max latency:" "$LINUX_OUTPUT" | grep -oE "[0-9]+" | head -1 || echo "0")

echo ""
echo "Linux Metrics:"
echo "  Average: $LINUX_AVG ns"
echo "  Min: $LINUX_MIN ns"
echo "  Max: $LINUX_MAX ns"

# Run seL4 metrics
echo ""
echo "Running seL4 metrics..."
"$SCRIPT_DIR/run_metrics.sh" ipc_demo qemu_virt_aarch64 debug "$ITERATIONS"

# Extract seL4 metrics from latest run
LATEST_RUN=$(ls -td "$PROJECT_ROOT/out/metrics"/*/ 2>/dev/null | head -1)
if [ -n "$LATEST_RUN" ] && [ -f "$LATEST_RUN/results.csv" ]; then
    SEL4_AVG=$(awk -F',' 'NR>1 {sum+=$2; count++} END {if(count>0) print int(sum/count); else print 0}' "$LATEST_RUN/results.csv")
    SEL4_MIN=$(awk -F',' 'NR>1 {if(min=="" || $2<min) min=$2} END {print min+0}' "$LATEST_RUN/results.csv")
    SEL4_MAX=$(awk -F',' 'NR>1 {if(max=="" || $2>max) max=$2} END {print max+0}' "$LATEST_RUN/results.csv")
    
    echo ""
    echo "seL4 Metrics:"
    echo "  Average: $SEL4_AVG ns"
    echo "  Min: $SEL4_MIN ns"
    echo "  Max: $SEL4_MAX ns"
    
    echo ""
    echo "Comparison:"
    if [ "$LINUX_AVG" -gt 0 ] && [ "$SEL4_AVG" -gt 0 ]; then
        RATIO=$(echo "scale=2; $LINUX_AVG / $SEL4_AVG" | bc)
        echo "  Linux/seL4 latency ratio: $RATIO"
    fi
fi

rm -f "$LINUX_OUTPUT"


