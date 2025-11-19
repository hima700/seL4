#!/bin/bash
#
# Clean script for seL4 Microkit build artifacts
# Usage: ./clean.sh [app_name]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

APP_NAME="${1:-all}"

if [ "$APP_NAME" = "all" ]; then
    echo "Cleaning all build artifacts..."
    rm -rf "$PROJECT_ROOT/out"
    echo "Clean complete."
else
    echo "Cleaning build artifacts for $APP_NAME..."
    rm -rf "$PROJECT_ROOT/out/$APP_NAME"*
    echo "Clean complete."
fi


