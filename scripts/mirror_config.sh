#!/bin/bash

# ONLYOFFICE 编译工具 - 仓库配置
# 当下载速度低于阈值时自动切换到备选仓库

# 下载速度阈值 (KB/s)
SPEED_THRESHOLD=500

# 是否强制使用备选仓库 (true/false/auto)
USE_MIRROR="${USE_MIRROR:-auto}"

# ==================== 仓库地址配置 ====================

# GitHub 官方仓库
declare -A GITHUB_REPOS
GITHUB_REPOS["build_tools"]="https://github.com/ONLYOFFICE/build_tools.git"
GITHUB_REPOS["document_server"]="https://github.com/ONLYOFFICE/DocumentServer.git"
GITHUB_REPOS["docker_document_server"]="https://github.com/ONLYOFFICE/Docker-DocumentServer.git"
GITHUB_REPOS["document_server_package"]="https://github.com/ONLYOFFICE/document-server-package.git"

# Gitee 备选仓库 (来自 https://gitee.com/toarujianshang/)
declare -A GITEE_REPOS
GITEE_REPOS["build_tools"]="https://gitee.com/toarujianshang/onlyoffice_build_tools.git"
GITEE_REPOS["document_server"]="https://gitee.com/toarujianshang/onlyoffice-document-server.git"
GITEE_REPOS["docker_document_server"]="https://gitee.com/toarujianshang/onlyoffice-docker-document-server.git"
GITEE_REPOS["document_server_package"]="https://gitee.com/toarujianshang/onglyoffice-document-server-package.git"

# ==================== 第三方组件镜像 ====================

# QT 下载地址
declare -A QT_MIRRORS
QT_MIRRORS["default"]="https://github.com/ONLYOFFICE-data/build_tools_data/raw/refs/heads/master/qt/qt-everywhere-opensource-src-5.9.9.tar.xz"
QT_MIRRORS["gitee"]="https://gitee.com/toarujianshang/build-tools-data/raw/master/qt/qt-everywhere-opensource-src-5.9.9.tar.xz"
QT_MIRRORS["ustc"]="https://mirrors.ustc.edu.cn/qtproject/official_releases/qt/5.9/5.9.9/single/qt-everywhere-opensource-src-5.9.9.tar.xz"
QT_MIRRORS["tsinghua"]="https://mirrors.tuna.tsinghua.edu.cn/qt/official_releases/qt/5.9/5.9.9/single/qt-everywhere-opensource-src-5.9.9.tar.xz"

# V8 下载地址
declare -A V8_MIRRORS
V8_MIRRORS["default"]="https://chromium.googlesource.com/v8/v8"
V8_MIRRORS["gitee"]="https://gitee.com/mirrors/v8.git"

# ICU 下载地址
declare -A ICU_MIRRORS
ICU_MIRRORS["default"]="https://github.com/unicode-org/icu"
ICU_MIRRORS["gitee"]="https://gitee.com/mirrors/icu4c"

# ==================== 速度检测函数 ====================

# 测试下载速度
# 返回值: 速度 KB/s
test_download_speed() {
    local url="$1"
    local test_file="/tmp/speed_test_$$"
    
    # 使用 curl 测试下载速度，限制时间 10 秒
    local speed=$(curl -s -o /dev/null -w "%{speed_download}" \
        --max-time 10 \
        --connect-timeout 5 \
        "$url" 2>/dev/null | awk '{print $1/1024}')
    
    rm -f "$test_file"
    
    if [ -z "$speed" ] || [ "$speed" = "0" ]; then
        echo "0"
    else
        echo "$speed"
    fi
}

# 检查是否需要切换到备选仓库
check_and_switch_mirror() {
    if [ "$USE_MIRROR" = "true" ]; then
        echo "强制使用备选仓库"
        return 0
    elif [ "$USE_MIRROR" = "false" ]; then
        echo "强制使用官方仓库"
        return 1
    fi
    
    # auto 模式：测试速度
    local test_url="${GITHUB_REPOS["build_tools"]}"
    echo "测试下载速度..."
    
    local speed=$(test_download_speed "$test_url")
    echo "当前速度: ${speed} KB/s"
    
    if [ "${speed%.*}" -lt "$SPEED_THRESHOLD" ]; then
        echo "速度低于阈值 (${SPEED_THRESHOLD} KB/s)，切换到备选仓库"
        return 0
    else
        echo "速度正常，使用官方仓库"
        return 1
    fi
}

# ==================== 获取仓库地址 ====================

get_repo_url() {
    local repo_name="$1"
    local use_gitee=0
    
    if check_and_switch_mirror; then
        use_gitee=1
    fi
    
    if [ $use_gitee -eq 1 ]; then
        echo "${GITEE_REPOS[$repo_name]}"
    else
        echo "${GITHUB_REPOS[$repo_name]}"
    fi
}

get_qt_mirror() {
    local mirror_name="${1:-default}"
    echo "${QT_MIRRORS[$mirror_name]}"
}

get_v8_mirror() {
    local mirror_name="${1:-default}"
    echo "${V8_MIRRORS[$mirror_name]}"
}

get_icu_mirror() {
    local mirror_name="${1:-default}"
    echo "${ICU_MIRRORS[$mirror_name]}"
}

# ==================== 导出函数供其他脚本使用 ====================

export -f test_download_speed
export -f check_and_switch_mirror
export -f get_repo_url
export -f get_qt_mirror
export -f get_v8_mirror
export -f get_icu_mirror
export SPEED_THRESHOLD
