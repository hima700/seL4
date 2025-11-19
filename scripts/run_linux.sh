#!/bin/bash
#
# Run Linux baseline client-server-logger
# Usage: ./run_linux.sh [iterations]
#

set -e

export PATH="/usr/bin:/bin:/usr/local/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ITERATIONS="${1:-10}"

LINUX_DIR="$PROJECT_ROOT/linux_baseline"
SERVER="$LINUX_DIR/server/server"
CLIENT="$LINUX_DIR/client/client"
LOGGER="$LINUX_DIR/logger/logger"

if [ ! -f "$SERVER" ] || [ ! -f "$CLIENT" ] || [ ! -f "$LOGGER" ]; then
    echo "Error: Linux binaries not found. Build first:"
    echo "  cd $LINUX_DIR && make"
    exit 1
fi

echo "Running Linux baseline (iterations=$ITERATIONS)"
echo ""

# Cleanup any existing sockets/shared memory
rm -f /tmp/sel4_linux_*.sock
rm -f /dev/shm/sel4_linux_shared

# Start logger in background
echo "Starting logger..."
$LOGGER &
LOGGER_PID=$!

sleep 1

# Start server in background
echo "Starting server..."
$SERVER &
SERVER_PID=$!

sleep 1

# Run client
echo "Running client ($ITERATIONS iterations)..."
$CLIENT "$ITERATIONS"
CLIENT_EXIT=$?

# Cleanup
echo ""
echo "Stopping server and logger..."
kill $SERVER_PID 2>/dev/null || true
kill $LOGGER_PID 2>/dev/null || true
sleep 1
kill -9 $SERVER_PID 2>/dev/null || true
kill -9 $LOGGER_PID 2>/dev/null || true

# Cleanup sockets/shared memory
rm -f /tmp/sel4_linux_*.sock
rm -f /dev/shm/sel4_linux_shared

exit $CLIENT_EXIT


