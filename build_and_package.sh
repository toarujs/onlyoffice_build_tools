#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_TOOLS_DIR="${SCRIPT_DIR}"
OUTPUT_DIR="${SCRIPT_DIR}/output"
ONLYOFFICE_PACKAGE_DIR="${OUTPUT_DIR}/package"

echo "=========================================="
echo "  ONLYOFFICE 编译打包脚本"
echo "=========================================="

mkdir -p "${OUTPUT_DIR}"
mkdir -p "${ONLYOFFICE_PACKAGE_DIR}/onlyoffice"
mkdir -p "${ONLYOFFICE_PACKAGE_DIR}/fonts"
mkdir -p "${ONLYOFFICE_PACKAGE_DIR}/config"
mkdir -p "${ONLYOFFICE_PACKAGE_DIR}/app/ds"

echo ""
echo "===== 第1步: 检查编译产物 ====="
if [ ! -d "${BUILD_TOOLS_DIR}/out/linux_64/onlyoffice/documentserver" ]; then
    echo "错误: 编译产物未找到!"
    echo "请先执行编译: docker run --rm -v \$(pwd):/build_tools onlyoffice-build:latest"
    exit 1
fi

echo ""
echo "===== 第2步: 复制编译产物 ====="
cp -r "${BUILD_TOOLS_DIR}/out/linux_64/onlyoffice/documentserver" "${ONLYOFFICE_PACKAGE_DIR}/onlyoffice/"

echo ""
echo "===== 第3步: 准备字体目录 ====="
mkdir -p "${ONLYOFFICE_PACKAGE_DIR}/fonts/truetype/custom"
mkdir -p "${ONLYOFFICE_PACKAGE_DIR}/fonts/truetype/msttcorefonts"

if [ -d "${ONLYOFFICE_PACKAGE_DIR}/onlyoffice/documentserver/core-fonts" ]; then
    cp -r "${ONLYOFFICE_PACKAGE_DIR}/onlyoffice/documentserver/core-fonts/"* "${ONLYOFFICE_PACKAGE_DIR}/fonts/truetype/custom/" 2>/dev/null || true
fi

echo ""
echo "===== 第4步: 复制配置文件 ====="
if [ -d "${SCRIPT_DIR}/config" ]; then
    cp -r "${SCRIPT_DIR}/config/"* "${ONLYOFFICE_PACKAGE_DIR}/config/"
fi

if [ -f "${SCRIPT_DIR}/run-document-server.sh" ]; then
    cp "${SCRIPT_DIR}/run-document-server.sh" "${ONLYOFFICE_PACKAGE_DIR}/app/ds/"
fi

if [ -d "${SCRIPT_DIR}/oracle" ]; then
    mkdir -p "${ONLYOFFICE_PACKAGE_DIR}/oracle"
    cp -r "${SCRIPT_DIR}/oracle/"* "${ONLYOFFICE_PACKAGE_DIR}/oracle/"
fi

echo ""
echo "===== 第5步: 设置权限 ====="
chmod +x "${ONLYOFFICE_PACKAGE_DIR}/app/ds/run-document-server.sh"

find "${ONLYOFFICE_PACKAGE_DIR}/onlyoffice/documentserver/server/FileConverter/bin/" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
find "${ONLYOFFICE_PACKAGE_DIR}/onlyoffice/documentserver/server/tools/" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

echo ""
echo "===== 第6步: 构建 DocumentServer 镜像 ====="
docker build -f "${BUILD_TOOLS_DIR}/Dockerfile.documentserver" \
    -t onlyoffice-documentserver:custom \
    -t onlyoffice-documentserver:latest \
    "${ONLYOFFICE_PACKAGE_DIR}"

echo ""
echo "=========================================="
echo "  编译打包完成!"
echo "=========================================="
echo ""
echo "运行 DocumentServer:"
echo "  docker run -d -p 80:80 -p 443:443 onlyoffice-documentserver:custom"
echo ""
echo "使用 docker-compose:"
echo "  docker-compose -f docker-compose.yml up -d"
echo ""
echo "查看日志:"
echo "  docker logs -f \$(docker ps -q --filter name=onlyoffice)"
