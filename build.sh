#!/bin/bash

# ONLYOFFICE DocumentServer 编译脚本
# 用法: ./build.sh [--skip-sysroot] [--skip-source-patch]

set -e

SKIP_SYSROOT=false
SKIP_SOURCE_PATCH=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-sysroot)
            SKIP_SYSROOT=true
            shift
            ;;
        --skip-source-patch)
            SKIP_SOURCE_PATCH=true
            shift
            ;;
        *)
            echo "未知参数: $1"
            exit 1
            ;;
    esac
done

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_TOOLS_DIR="$SCRIPT_DIR"
BUILD_OUTPUT="/build_output"

echo "=========================================="
echo "  ONLYOFFICE 编译脚本"
echo "=========================================="

# ========== 第1步: 环境检测 =====

echo ""
echo "===== 第1步: 环境检测 ====="

if ! command -v apt-get &> /dev/null; then
    echo "错误: 需要 Debian/Ubuntu 系统"
    exit 1
fi

echo "更新软件源..."
apt-get update

echo "安装基础依赖..."
apt-get install -y \
    sudo git git-lfs curl wget p7zip-full \
    build-essential python3 python3-pip \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
    libsqlite3-dev llvm libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev libffi-dev liblzma-dev \
    libxml2-dev libxslt1-dev uuid-dev pkg-config subversion \
    g++ make

if [ ! -f /usr/bin/python ]; then
    ln -s /usr/bin/python3 /usr/bin/python
fi

echo "基础环境安装完成"

# ========== 第2步: Git 镜像 ==========

echo ""
echo "===== 第2步: 配置 Git 镜像 ====="

git config --global url."https://gitee.com/".insteadOf "https://github.com/"
echo "Git 镜像配置完成"

# ========== 第3步: 检查仓库 ==========

echo ""
echo "===== 第3步: 检查 build_tools ====="

cd "$BUILD_TOOLS_DIR"

if [ ! -d "$BUILD_TOOLS_DIR" ]; then
    echo "错误: build_tools 目录不存在"
    exit 1
fi

# ========== 第4步: Python 环境 ==========

echo ""
echo "===== 第4步: 安装 Python 环境 ====="

PYTHON_DIR="$BUILD_TOOLS_DIR/tools/linux/python3"
mkdir -p "$PYTHON_DIR/bin"
ln -sf /usr/bin/python3 "$PYTHON_DIR/bin/python3"
ln -sf python3 "$PYTHON_DIR/bin/python"
echo "Python 环境就绪"

# ========== 第5步: Sysroot ==========

echo ""
echo "===== 第5步: 下载 Sysroot ====="

if [ "$SKIP_SYSROOT" = true ]; then
    echo "跳过 Sysroot 下载"
else
    cd "$BUILD_TOOLS_DIR/tools/linux/sysroot"
    if "$PYTHON_DIR/bin/python3" ./fetch.py amd64; then
        echo "Sysroot 下载完成"
    else
        echo "Sysroot 下载失败，继续..."
    fi
fi

# ========== 第6步: 系统依赖 ==========

echo ""
echo "===== 第6步: 安装系统依赖 ====="

cd "$BUILD_TOOLS_DIR/tools/linux"
"$PYTHON_DIR/bin/python3" ./deps.py
echo "系统依赖安装完成"

# ========== 第7步: CMake ==========

echo ""
echo "===== 第7步: 安装 CMake ====="

cd "$BUILD_TOOLS_DIR/tools/linux"
./cmake.sh
echo "CMake 安装完成"

# ========== 第8步: 源码修改 ==========

echo ""
echo "===== 第8步: 源码修改 ====="

if [ "$SKIP_SOURCE_PATCH" = true ]; then
    echo "跳过源码修改"
else
    CONTANTS_FILE="$BUILD_TOOLS_DIR/server/Common/sources/contants.js"
    LICENSE_FILE="$BUILD_TOOLS_DIR/server/Common/sources/license.js"
    AUTOMATE_FILE="$BUILD_TOOLS_DIR/tools/linux/automate.py"

    if [ -f "$CONTANTS_FILE" ]; then
        sed -i 's/LICENSE_CONNECTIONS = [0-9]*/LICENSE_CONNECTIONS = 2000/' "$CONTANTS_FILE"
        echo "- 连接数已修改为 2000"
    fi

    if [ -f "$LICENSE_FILE" ]; then
        sed -i 's/advancedApi: false/advancedApi: true/' "$LICENSE_FILE"
        echo "- advancedApi 已开启"
    fi

    if [ -f "$AUTOMATE_FILE" ]; then
        sed -i 's/"--update", "1"/"--update", "0"/' "$AUTOMATE_FILE"
        echo "- 源码更新已关闭"
    fi
fi

# ========== 第9步: 编译 ==========

echo ""
echo "===== 第9步: 执行编译 ====="
echo "编译可能需要 3-5 小时..."

cd "$BUILD_TOOLS_DIR/tools/linux"
export DO_NOT_USE_PREBUILD_QT=1
./automate.py server --update=0

# ========== 第10步: 产物 ==========

echo ""
echo "===== 第10步: 复制编译产物 ====="

mkdir -p "$BUILD_OUTPUT"
if [ -d "$BUILD_TOOLS_DIR/out/linux_64/onlyoffice" ]; then
    cp -r "$BUILD_TOOLS_DIR/out/linux_64/onlyoffice" "$BUILD_OUTPUT/"
    echo "编译产物已复制到 $BUILD_OUTPUT"
else
    echo "警告: 未找到编译产物"
fi

echo ""
echo "=========================================="
echo "  编译完成!"
echo "=========================================="
