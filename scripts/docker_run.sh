#!/bin/bash
#
# Build and run the project in a Docker container
# Usage: ./scripts/docker_run.sh [iterations]
#

set -e

ITERATIONS="${1:-5}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_NAME="sel4"
CONTAINER_NAME="sel4-runner"

echo "Building Docker image (cached layers reused when possible)..."
docker build -t "$IMAGE_NAME" "$PROJECT_ROOT"

echo "Running metrics pipeline in Docker..."
# Remove any stale container with same name
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

# Mount the 'out' directory to persist results on the host
docker run --rm \
    --name "$CONTAINER_NAME" \
    -v "$PROJECT_ROOT/out:/app/out" \
    "$IMAGE_NAME" \
    ./scripts/run_all_metrics.sh "$ITERATIONS"

echo ""
echo "Docker run complete. Results are in seL4/out/"

