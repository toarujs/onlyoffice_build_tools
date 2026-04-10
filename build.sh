#!/bin/bash

# ONLYOFFICE DocumentServer 编译脚本
# 用法: ./build.sh

set -e

echo "=========================================="
echo "  ONLYOFFICE 编译脚本"
echo "=========================================="

# 配置
WORK_DIR="/root/onlyoffice_build_tools"
BUILD_OUTPUT="/build_output"

# 配置 Git 镜像
echo "配置 Git 镜像..."
git config --global url."https://gitee.com/".insteadOf "https://github.com/"

# 克隆仓库
echo "克隆 build_tools..."
cd /root
if [ -d "$WORK_DIR" ]; then
    echo "更新现有仓库..."
    cd "$WORK_DIR"
    git pull
else
    git clone https://gitee.com/toarujianshang/onlyoffice_build_tools.git "$WORK_DIR"
    cd "$WORK_DIR"
fi

cd "$WORK_DIR/tools/linux"

# 安装 Python
echo "安装 Python..."
if ! command -v python3 &> /dev/null; then
    apt-get update && apt-get install -y python3 python3-pip
fi
mkdir -p python3/bin
ln -sf "$(which python3)" python3/bin/python3
ln -sf python3 python3/bin/python

# 创建 python 链接
if [ ! -f /usr/bin/python ]; then
    ln -s /usr/bin/python3 /usr/bin/python
fi

# 下载 Sysroot
echo "下载 Sysroot..."
cd sysroot
../python3/bin/python3 ./fetch.py amd64
cd ..

# 安装系统依赖
echo "安装系统依赖..."
../python3/bin/python3 ./deps.py

# 安装 CMake
echo "安装 CMake..."
./cmake.sh

# 修改源码
echo "修改源码..."
CONTANTS_FILE="$WORK_DIR/server/Common/sources/contants.js"
LICENSE_FILE="$WORK_DIR/server/Common/sources/license.js"
AUTOMATE_FILE="$WORK_DIR/tools/linux/automate.py"

if [ -f "$CONTANTS_FILE" ]; then
    sed -i 's/LICENSE_CONNECTIONS = [0-9]*/LICENSE_CONNECTIONS = 2000/' "$CONTANTS_FILE"
    echo "连接数已修改为 2000"
fi

if [ -f "$LICENSE_FILE" ]; then
    sed -i 's/advancedApi: false/advancedApi: true/' "$LICENSE_FILE"
    echo "advancedApi 已开启"
fi

if [ -f "$AUTOMATE_FILE" ]; then
    sed -i 's/"--update", "1"/"--update", "0"/' "$AUTOMATE_FILE"
    echo "源码更新已关闭"
fi

# 执行编译
echo "执行编译..."
export DO_NOT_USE_PREBUILD_QT=1
./automate.py server --update=0

echo ""
echo "=========================================="
echo "  编译完成!"
echo "=========================================="

# 复制产物
echo "复制编译产物到 $BUILD_OUTPUT..."
mkdir -p "$BUILD_OUTPUT"
docker cp onlyoffice-build:/root/onlyoffice_build_tools/out/linux_64/onlyoffice "$BUILD_OUTPUT/"

echo "完成!"
