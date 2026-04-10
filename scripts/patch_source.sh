#!/bin/bash

set -e

PATCH_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_TOOLS_DIR="${PATCH_SCRIPT_DIR}"

echo "===== ONLYOFFICE 源码修改脚本 ====="
echo "Build Tools 目录: ${BUILD_TOOLS_DIR}"

cd "${BUILD_TOOLS_DIR}"

# ==================== 速度检测 ====================

test_speed() {
    local url="$1"
    curl -s -o /dev/null -w "%{speed_download}" \
        --max-time 10 \
        --connect-timeout 5 \
        "$url" 2>/dev/null | awk '{print $1/1024}'
}

echo ""
echo "===== 第0步: 检测网络速度 ====="
SPEED=$(test_speed "https://github.com")
SPEED_INT=${SPEED%.*}

echo "GitHub 下载速度: ${SPEED} KB/s"

if [ -z "$SPEED_INT" ] || [ "$SPEED_INT" -lt 500 ]; then
    echo "速度低于 500KB/s，启用国内镜像"
    USE_MIRROR=1
else
    echo "速度正常"
    USE_MIRROR=0
fi

# ==================== 源码修改 ====================

echo ""
echo "===== 第1步: 修改连接数 ====="
CONTANTS_FILE="server/Common/sources/contants.js"
if [ -f "${CONTANTS_FILE}" ]; then
    sed -i 's/LICENSE_CONNECTIONS = [0-9]*/LICENSE_CONNECTIONS = 2000/' "${CONTANTS_FILE}"
    echo "已修改连接数为 2000"
else
    echo "警告: 文件不存在 ${CONTANTS_FILE}"
fi

echo ""
echo "===== 第2步: 开启 advancedApi ====="
LICENSE_FILE="server/Common/sources/license.js"
if [ -f "${LICENSE_FILE}" ]; then
    sed -i 's/advancedApi: false/advancedApi: true/' "${LICENSE_FILE}"
    echo "已开启 advancedApi"
else
    echo "警告: 文件不存在 ${LICENSE_FILE}"
fi

echo ""
echo "===== 第3步: 修改 QT 下载地址 ====="
AUTOMATE_FILE="tools/linux/automate.py"
if [ -f "${AUTOMATE_FILE}" ]; then
    if [ $USE_MIRROR -eq 1 ]; then
        # 使用中科大镜像
        sed -i 's|https://github.com/ONLYOFFICE-data/build_tools_data/raw/refs/heads/master/qt/qt-everywhere-opensource-src-5.9.9.tar.xz|https://mirrors.ustc.edu.cn/qtproject/official_releases/qt/5.9/5.9.9/single/qt-everywhere-opensource-src-5.9.9.tar.xz|g' "${AUTOMATE_FILE}"
        sed -i 's|"https://github.com/ONLYOFFICE-data/build_tools_data/raw/refs/heads/master/qt/"|"https://mirrors.ustc.edu.cn/qtproject/official_releases/qt/5.9/5.9.9/single/"|g' "${AUTOMATE_FILE}"
        echo "已修改为中科大镜像"
    else
        sed -i 's|"https://github.com/ONLYOFFICE-data/build_tools_data/raw/refs/heads/master/qt/"|"https://github.com/ONLYOFFICE-data/build_tools_data/raw/refs/heads/master/qt/"|g' "${AUTOMATE_FILE}"
        echo "使用官方地址"
    fi
fi

QT_FETCH_FILE="tools/linux/qt_binary_fetch.py"
if [ -f "${QT_FETCH_FILE}" ]; then
    if [ $USE_MIRROR -eq 1 ]; then
        sed -i 's|"https://github.com/ONLYOFFICE-data/build_tools_data/raw/refs/heads/master/qt/"|"https://gitee.com/toarujianshang/build-tools-data/raw/master/qt/"|g' "${QT_FETCH_FILE}"
        echo "已修改 qt_binary_fetch.py 使用 Gitee 镜像"
    fi
fi

echo ""
echo "===== 第4步: 添加 connector.api 方法 ====="
PLUGINS_FILE="sdkjs/common/plugins.js"
if [ -f "${PLUGINS_FILE}" ]; then
    if ! grep -q "historyTurnOff" "${PLUGINS_FILE}"; then
        sed -i '/case "externalConnectorMessage"/,/break;/ {
            /break;/ a\
        case "historyTurnOff":\
            AscCommon.History.TurnOff();\
            break;\
        case "historyTurnOn":\
            AscCommon.History.TurnOn();\
            break;
        }' "${PLUGINS_FILE}"
        echo "已添加 historyTurnOff/historyTurnOn 方法"
    else
        echo "connector.api 方法已存在，跳过"
    fi
fi

echo ""
echo "===== 第5步: 修改 automate.py 关闭源码更新 ====="
if [ -f "${AUTOMATE_FILE}" ]; then
    sed -i 's/"--update", "1"/"--update", "0"/' "${AUTOMATE_FILE}"
    echo "已关闭源码更新"
fi

echo ""
echo "===== 第6步: 配置 ICU 下载镜像 ====="
ICU_FILE="scripts/core_common/modules/icu.py"
if [ -f "${ICU_FILE}" ]; then
    if [ $USE_MIRROR -eq 1 ]; then
        sed -i 's|https://github.com/unicode-org/icu.git|https://gitee.com/mirrors/icu4c.git|g' "${ICU_FILE}"
        echo "已配置 ICU 使用 Gitee 镜像"
    fi
fi

echo ""
echo "===== 第7步: 配置 Git 全局镜像 ====="
if [ $USE_MIRROR -eq 1 ]; then
    git config --global url."https://gitee.com/".insteadOf "https://github.com/"
    git config --global url."https://gitee.com/toarujianshang/".insteadOf "https://github.com/ONLYOFFICE/"
    echo "已配置 Git 全局使用 Gitee 镜像"
fi

echo ""
echo "===== 源码修改完成 ====="

if [ $USE_MIRROR -eq 1 ]; then
    echo ""
    echo "已启用国内镜像加速"
    echo "QT: 中科大镜像"
    echo "ICU: Gitee 镜像"
    echo "Git: Gitee 镜像"
fi
