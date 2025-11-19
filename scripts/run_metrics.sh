#!/bin/bash
#
# Metrics runner: Run N iterations and collect data
# Usage: ./run_metrics.sh [app_name] [board] [config] [iterations]
#

set -e

export PATH="/usr/bin:/bin:/usr/local/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

APP_NAME="${1:-ipc_demo}"
BOARD="${2:-qemu_virt_aarch64}"
CONFIG="${3:-debug}"
ITERATIONS="${4:-10}"

OUTPUT_DIR="$PROJECT_ROOT/out/metrics"
TIMESTAMP=$(date +%Y%m%d-%H%M)
RESULTS_DIR="$OUTPUT_DIR/$TIMESTAMP"
RESULTS_CSV="$RESULTS_DIR/results.csv"

mkdir -p "$RESULTS_DIR"

echo "Running metrics collection"
echo "App: $APP_NAME"
echo "Board: $BOARD"
echo "Config: $CONFIG"
echo "Iterations: $ITERATIONS"
echo "Results directory: $RESULTS_DIR"
echo ""

# Build if needed
BUILD_DIR="$PROJECT_ROOT/out/$APP_NAME-$BOARD-$CONFIG"
IMAGE_FILE="$BUILD_DIR/loader.img"

if [ ! -f "$IMAGE_FILE" ]; then
    echo "Building $APP_NAME..."
    "$SCRIPT_DIR/build.sh" "$APP_NAME" "$BOARD" "$CONFIG"
fi

# Initialize CSV file
echo "iteration,latency_ns,timestamp" > "$RESULTS_CSV"

echo "Running $ITERATIONS iterations..."
for i in $(seq 1 $ITERATIONS); do
    echo "Iteration $i/$ITERATIONS..."
    
    # Run QEMU and capture output
    LOG_FILE="$RESULTS_DIR/run_${i}.log"
    
    # Check if QEMU is available
    if ! command -v qemu-system-aarch64 > /dev/null 2>&1; then
        echo "  ERROR: qemu-system-aarch64 not found in PATH"
        echo "  Please install QEMU: sudo apt install qemu-system-arm"
        exit 1
    fi
    
    # Run QEMU with timeout - need longer timeout for full boot
    # Use Python to capture output reliably even without TTY
    # This bypasses shell redirection buffering issues
    RUN_CMD=("$SCRIPT_DIR/run.sh" "$APP_NAME" "$BOARD" "$CONFIG")
    
    if command -v script > /dev/null 2>&1; then
        # Use script if available (best for QEMU as it allocates a PTY)
        timeout 60 script -q -c "${RUN_CMD[*]}" "$LOG_FILE" >/dev/null 2>&1 || true
    else
        # Fallback to Python PTY execution if python3 is available
        if command -v python3 > /dev/null 2>&1; then
            timeout 60 python3 - "$LOG_FILE" "${RUN_CMD[@]}" <<'EOF' >/dev/null 2>&1 || true
import sys, subprocess, pty, os

log_file = sys.argv[1]
cmd = sys.argv[2:]

try:
    # Fork a PTY to make QEMU think it's interactive (flushes stdout properly)
    pid, fd = pty.fork()
    if pid == 0:
        os.execvp(cmd[0], cmd)
    else:
        with open(log_file, 'wb') as f:
            while True:
                try:
                    data = os.read(fd, 1024)
                    if not data: break
                    f.write(data)
                    f.flush()
                except OSError:
                    break
        os.wait()
except Exception as e:
    # Fallback to standard subprocess if PTY fails
    with open(log_file, 'w') as f:
        subprocess.run(cmd, stdout=f, stderr=subprocess.STDOUT)
EOF
        else
            # Last resort: direct execution
            timeout 60 bash -c "${RUN_CMD[*]}" > "$LOG_FILE" 2>&1 || true
        fi
    fi
    
    if [ ! -s "$LOG_FILE" ]; then
        echo "  ERROR: Failed to capture QEMU output (log file empty)"
        echo "  Debug: Command was: ${RUN_CMD[*]}"
    fi
    
    if grep -q "Error: qemu-system-aarch64 not found" "$LOG_FILE"; then
        cat "$LOG_FILE"
        exit 1
    fi
    
    # Wait a bit for QEMU to fully boot and output
    sleep 3
    
    # Extract latency from log (look for CLIENT|METRIC: latency=)
    # Pattern: CLIENT|METRIC: latency=XXXXX ns
    # Search entire file, not just last lines
    LATENCY=$(grep -E "CLIENT\|METRIC.*latency" "$LOG_FILE" 2>/dev/null | grep -oE "latency=[0-9]+" | grep -oE "[0-9]+" | head -1 || echo "")
    
    # If not found, try alternative pattern - look for any number after "latency="
    if [ -z "$LATENCY" ]; then
        LATENCY=$(grep -E "CLIENT\|METRIC" "$LOG_FILE" 2>/dev/null | grep -i "latency" | grep -oE "[0-9]+" | head -1 || echo "")
    fi
    
    # If still not found, try finding any number in CLIENT|METRIC lines
    if [ -z "$LATENCY" ]; then
        LATENCY=$(grep -E "CLIENT\|METRIC" "$LOG_FILE" 2>/dev/null | grep -oE "[0-9]{4,}" | head -1 || echo "")
    fi
    
    # Debug: show what we found
    if [ -z "$LATENCY" ]; then
        echo "  Debug: Checking log file for CLIENT/METRIC lines..."
        grep -E "CLIENT|METRIC" "$LOG_FILE" 2>/dev/null | tail -5 || echo "  Debug: No CLIENT or METRIC lines found in log"
        echo "  Debug: Log file size: $(wc -l < "$LOG_FILE" 2>/dev/null || echo 0) lines"
    fi
    
    if [ -n "$LATENCY" ]; then
        echo "$i,$LATENCY,$(date +%s)" >> "$RESULTS_CSV"
        echo "  Latency: $LATENCY ns"
    else
        echo "  Warning: Could not extract latency"
    fi
    
    sleep 1
done

echo ""
echo "Metrics collection complete"
echo "Results saved to: $RESULTS_CSV"
echo "Logs saved to: $RESULTS_DIR/"

