#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_TOOLS_DIR="${SCRIPT_DIR}"
OUTPUT_DIR="${SCRIPT_DIR}/output"
ONLYOFFICE_PACKAGE_DIR="${OUTPUT_DIR}/package-api"

echo "=========================================="
echo "  ONLYOFFICE API 精简版打包脚本"
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
    echo "请先执行编译"
    exit 1
fi

echo ""
echo "===== 第2步: 复制编译产物 ====="
cp -r "${BUILD_TOOLS_DIR}/out/linux_64/onlyoffice/documentserver" "${ONLYOFFICE_PACKAGE_DIR}/onlyoffice/"

echo ""
echo "===== 第3步: 准备字体目录 ====="
mkdir -p "${ONLYOFFICE_PACKAGE_DIR}/fonts/truetype/custom"

if [ -d "${ONLYOFFICE_PACKAGE_DIR}/onlyoffice/documentserver/core-fonts" ]; then
    cp -r "${ONLYOFFICE_PACKAGE_DIR}/onlyoffice/documentserver/core-fonts/"* "${ONLYOFFICE_PACKAGE_DIR}/fonts/truetype/custom/" 2>/dev/null || true
fi

echo ""
echo "===== 第4步: 复制配置文件 ====="
cp -r "${SCRIPT_DIR}/config/supervisor/supervisord-api.conf" "${ONLYOFFICE_PACKAGE_DIR}/config/supervisord.conf"
cp -r "${SCRIPT_DIR}/config/supervisor/conf.d/ds-api.conf" "${ONLYOFFICE_PACKAGE_DIR}/config/supervisor/conf.d/"
cp "${SCRIPT_DIR}/run-document-server-api.sh" "${ONLYOFFICE_PACKAGE_DIR}/app/ds/run-document-server.sh"

echo ""
echo "===== 第5步: 设置权限 ====="
chmod +x "${ONLYOFFICE_PACKAGE_DIR}/app/ds/run-document-server.sh"
find "${ONLYOFFICE_PACKAGE_DIR}/onlyoffice/documentserver/server/FileConverter/bin/" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

echo ""
echo "===== 第6步: 构建 API 精简版镜像 ====="
docker build -f "${BUILD_TOOLS_DIR}/Dockerfile.documentserver-api" \
    -t onlyoffice-documentserver:api \
    "${ONLYOFFICE_PACKAGE_DIR}"

echo ""
echo "=========================================="
echo "  API 精简版打包完成!"
echo "=========================================="
echo ""
echo "运行 (无 SSL):"
echo "  docker run -d -p 8080:80 onlyoffice-documentserver:api"
echo ""
echo "运行 (带 SSL 证书挂载):"
echo "  docker run -d -p 8443:443 -v /path/to/ssl:/etc/letsencrypt onlyoffice-documentserver:api"
echo ""
echo "使用 docker-compose:"
echo "  SSL 证书放在 ./ssl/ 目录下，结构:"
echo "    ./ssl/live/onlyoffice/fullchain.pem"
echo "    ./ssl/live/onlyoffice/privkey.pem"
