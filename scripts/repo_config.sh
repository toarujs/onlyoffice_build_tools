#!/bin/bash

# 备选仓库配置文件
# 当下载速度低于 500KB/s 时自动切换到备选仓库

# ==================== ONLYOFFICE 仓库 ====================

# GitHub 官方仓库
GITHUB_BUILD_TOOLS="https://github.com/ONLYOFFICE/build_tools.git"
GITHUB_DOCUMENT_SERVER="https://github.com/ONLYOFFICE/DocumentServer.git"
GITHUB_DOCKER_DOCUMENT_SERVER="https://github.com/ONLYOFFICE/Docker-DocumentServer.git"
GITHUB_DOCUMENT_SERVER_PACKAGE="https://github.com/ONLYOFFICE/document-server-package.git"

# Gitee 备选仓库 (来自 https://gitee.com/toarujianshang/)
GITEE_BUILD_TOOLS="https://gitee.com/toarujianshang/onlyoffice_build_tools.git"
GITEE_DOCUMENT_SERVER="https://gitee.com/toarujianshang/onlyoffice-document-server.git"
GITEE_DOCKER_DOCUMENT_SERVER="https://gitee.com/toarujianshang/onlyoffice-docker-document-server.git"
GITEE_DOCUMENT_SERVER_PACKAGE="https://gitee.com/toarujianshang/onglyoffice-document-server-package.git"

# ==================== Qt 镜像 ====================

QT_MIRROR_DEFAULT="https://github.com/ONLYOFFICE-data/build_tools_data/raw/refs/heads/master/qt/qt-everywhere-opensource-src-5.9.9.tar.xz"
QT_MIRROR_GITEE="https://gitee.com/toarujianshang/build-tools-data/raw/master/qt/qt-everywhere-opensource-src-5.9.9.tar.xz"
QT_MIRROR_USTC="https://mirrors.ustc.edu.cn/qtproject/official_releases/qt/5.9/5.9.9/single/qt-everywhere-opensource-src-5.9.9.tar.xz"
QT_MIRROR_TSINGHUA="https://mirrors.tuna.tsinghua.edu.cn/qt/official_releases/qt/5.9/5.9.9/single/qt-everywhere-opensource-src-5.9.9.tar.xz"

# ==================== V8 镜像 ====================

V8_MIRROR_DEFAULT="https://chromium.googlesource.com/v8/v8"
V8_MIRROR_GITEE="https://gitee.com/mirrors/v8.git"

# ==================== ICU 镜像 ====================

ICU_MIRROR_DEFAULT="https://github.com/unicode-org/icu"
ICU_MIRROR_GITEE="https://gitee.com/mirrors/icu4c"

# ==================== 其他镜像 ====================

# NPM 镜像 (可选)
NPM_MIRROR="https://registry.npmmirror.com"

# PIP 镜像 (可选)
PIP_MIRROR="https://pypi.tuna.tsinghua.edu.cn/simple"

# ==================== 辅助函数 ====================

# 测试下载速度
# 返回: 速度 KB/s
test_speed() {
    local url="$1"
    curl -s -o /dev/null -w "%{speed_download}" \
        --max-time 10 \
        --connect-timeout 5 \
        "$url" 2>/dev/null | awk '{print $1/1024}'
}

# 检查是否需要切换镜像
check_mirror() {
    local url="$GITHUB_BUILD_TOOLS"
    local speed=$(test_speed "$url")
    local speed_int=${speed%.*}
    
    echo "测试 GitHub 下载速度: ${speed} KB/s"
    
    if [ -z "$speed_int" ] || [ "$speed_int" -lt 500 ]; then
        echo "速度低于 500KB/s，切换到备选仓库"
        return 0
    else
        echo "速度正常，使用官方仓库"
        return 1
    fi
}

# 输出配置
echo "===== 仓库配置 ====="

if check_mirror; then
    echo "使用 Gitee 备选仓库"
    USE_MIRROR=true
else
    echo "使用 GitHub 官方仓库"
    USE_MIRROR=false
fi

# 导出变量
export USE_MIRROR
export QT_MIRROR="${QT_MIRROR_USTC}"
export V8_MIRROR="${V8_MIRROR_GITEE}"
export ICU_MIRROR="${ICU_MIRROR_GITEE}"

echo "QT_MIRROR: $QT_MIRROR"
echo "V8_MIRROR: $V8_MIRROR"
echo "ICU_MIRROR: $ICU_MIRROR"
