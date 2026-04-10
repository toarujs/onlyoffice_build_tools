#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_TOOLS_DATA_DIR="/tmp/build_tools_data"

echo "Cloning build_tools_data repository..."

# 直接克隆整个仓库
if [ ! -d "$BUILD_TOOLS_DATA_DIR" ]; then
    git clone --depth 1 https://gitee.com/toarujianshang/onlyoffice-build_tools_data.git "$BUILD_TOOLS_DATA_DIR"
fi

# 复制 Python 文件
echo "Copying Python files..."
cp -f "$BUILD_TOOLS_DATA_DIR/python/python3.tar.gz "$SCRIPT_DIR/
cp -f "$BUILD_TOOLS_DATA_DIR/python/extract.sh" "$SCRIPT_DIR/"

chmod +x "$SCRIPT_DIR/extract.sh"
cd "$SCRIPT_DIR"
./extract.sh

cd "$SCRIPT_DIR/python3/bin"
ln -s python3 python
cd "$SCRIPT_DIR/"

rm -rf "$BUILD_TOOLS_DATA_DIR"
rm -f "$SCRIPT_DIR/extract.sh"
rm -f "$SCRIPT_DIR/python3.tar.gz"

echo "Python setup complete."
