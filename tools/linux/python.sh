#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Checking for Python3..."

# Check if Python3 already exists
if command -v python3 &> /dev/null; then
    echo "Python3 found: $(python3 --version)"
    
    # Create directory structure for compatibility
    mkdir -p "$SCRIPT_DIR/python3/bin"
    
    # Check if python3 is usable
    if python3 -c "import sys; print(sys.version)" &> /dev/null; then
        ln -sf "$(which python3)" "$SCRIPT_DIR/python3/bin/python3"
        ln -sf python3 "$SCRIPT_DIR/python3/bin/python"
        echo "Python setup complete (using system Python)."
        exit 0
    fi
fi

echo "Installing Python3..."
apt-get update && apt-get install -y python3 python3-pip

mkdir -p "$SCRIPT_DIR/python3/bin"
ln -sf "$(which python3)" "$SCRIPT_DIR/python3/bin/python3"
ln -sf python3 "$SCRIPT_DIR/python3/bin/python"

echo "Python setup complete."
