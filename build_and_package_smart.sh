#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_TOOLS_DIR="${SCRIPT_DIR}"
OUTPUT_DIR="${SCRIPT_DIR}/output"
ONLYOFFICE_BUILD_DIR="${OUTPUT_DIR}/onlyoffice-build"
ONLYOFFICE_PACKAGE_DIR="${OUTPUT_DIR}/onlyoffice-package"

# 引入镜像配置
source "${SCRIPT_DIR}/scripts/mirror_config.sh"

# 速度阈值 (KB/s)，低于此值切换镜像
SPEED_THRESHOLD=500

echo "=========================================="
echo "  ONLYOFFICE 编译打包脚本 (智能镜像版)"
echo "=========================================="

# 检查速度并选择仓库
echo ""
echo "===== 第0步: 检测网络速度并选择仓库 ====="
if check_and_switch_mirror; then
    USE_GITEE=1
    echo "将使用 Gitee 备选仓库"
else
    USE_GITEE=0
    echo "将使用 GitHub 官方仓库"
fi

mkdir -p "${OUTPUT_DIR}"
mkdir -p "${ONLYOFFICE_PACKAGE_DIR}/onlyoffice"
mkdir -p "${ONLYOFFICE_PACKAGE_DIR}/fonts"
mkdir -p "${ONLYOFFICE_PACKAGE_DIR}/config/supervisor/ds"

echo ""
echo "===== 第1步: 构建编译环境镜像 ====="

# 根据网络选择构建参数
if [ $USE_GITEE -eq 1 ]; then
    cat > "${BUILD_TOOLS_DIR}/Dockerfile.build.mirror" << 'EOF'
FROM ubuntu:24.04

LABEL maintainer="ONLYOFFICE Build Environment (Mirror)"

ENV TZ=Etc/UTC
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN echo 'keyboard-configuration keyboard-configuration/layoutcode string us' | debconf-set-selections && \
    echo 'keyboard-configuration keyboard-configuration/modelcode string pc105' | debconf-set-selections

RUN apt-get -y update && \
    apt-get -y install \
        sudo \
        git \
        git-lfs \
        curl \
        wget \
        p7zip-full \
        ca-certificates \
        gnupg \
        lsb-release \
        build-essential \
        python3 \
        python3-pip \
        python3-dev \
        libssl-dev \
        zlib1g-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        llvm \
        libncurses5-dev \
        libncursesw5-dev \
        xz-utils \
        tk-dev \
        libffi-dev \
        liblzma-dev \
        libxml2-dev \
        libxslt1-dev \
        uuid-dev \
        pkg-config \
        subversion

# 配置 Git 使用国内镜像
RUN git config --global url."https://gitee.com/".insteadOf "https://github.com/" && \
    git config --global url."https://gitee.com/toarujianshang/".insteadOf "https://github.com/ONLYOFFICE/"

ADD . /build_tools
WORKDIR /build_tools

RUN cd tools/linux && \
    ./python.sh

RUN cd tools/linux && \
    ./python3/bin/python3 ./qt_binary_fetch.py amd64

RUN cd tools/linux && \
    ./python3/bin/python3 ./deps.py

RUN cd tools/linux && \
    ./cmake.sh

RUN cd tools/linux/sysroot && \
    ../python3/bin/python3 ./fetch.py amd64

ARG BRANCH=master
ENV BRANCH=${BRANCH}

VOLUME ["/build_output"]

CMD ["sh", "-c", "cd /build_tools && ./tools/linux/python3/bin/python3 ./configure.py --sysroot \"1\" --clean \"0\" --update-light \"1\" --branch \"${BRANCH}\" --update \"1\" --module \"desktop server builder\" --qt-dir \"$(pwd)/tools/linux/qt_build/Qt-5.9.9\" && ./tools/linux/python3/bin/python3 ./make.py && cp -r out/linux_64/onlyoffice /build_output/"]
EOF
    DOCKERFILE="${BUILD_TOOLS_DIR}/Dockerfile.build.mirror"
else
    DOCKERFILE="${BUILD_TOOLS_DIR}/Dockerfile.build"
fi

docker build -f "${DOCKERFILE}" \
    -t onlyoffice-build:latest \
    "${BUILD_TOOLS_DIR}"

echo ""
echo "===== 第2步: 清理旧容器 ====="
docker rm -f onlyoffice-build 2>/dev/null || true

echo ""
echo "===== 第3步: 运行编译容器 ====="
docker run -d \
    --name onlyoffice-build \
    -v onlyoffice-build-data:/build_output \
    onlyoffice-build:latest

echo ""
echo "===== 第4步: 等待编译完成（约需数小时）====="
echo "查看编译日志: docker logs -f onlyoffice-build"
echo "等待容器完成..."

while docker container inspect -f '{{.State.Running}}' onlyoffice-build 2>/dev/null | grep -q "true"; do
    sleep 30
done

docker wait onlyoffice-build || true

echo ""
echo "===== 第5步: 复制编译产物 ====="
docker cp onlyoffice-build:/build_output/onlyoffice "${ONLYOFFICE_PACKAGE_DIR}/"

if [ ! -d "${ONLYOFFICE_PACKAGE_DIR}/onlyoffice/documentserver" ]; then
    echo "错误: 编译产物未找到!"
    exit 1
fi

echo ""
echo "===== 第6步: 准备打包目录 ====="

if [ -d "${ONLYOFFICE_PACKAGE_DIR}/onlyoffice/documentserver/server/FileConverter/bin" ]; then
    chmod +x "${ONLYOFFICE_PACKAGE_DIR}/onlyoffice/documentserver/server/FileConverter/bin"
fi

echo ""
echo "===== 第7步: 创建字体目录 ====="
mkdir -p "${ONLYOFFICE_PACKAGE_DIR}/fonts/truetype"
mkdir -p "${ONLYOFFICE_PACKAGE_DIR}/usr/share/fonts/truetype/custom"

if [ -d "${ONLYOFFICE_PACKAGE_DIR}/onlyoffice/documentserver/core-fonts" ]; then
    cp -r "${ONLYOFFICE_PACKAGE_DIR}/onlyoffice/documentserver/core-fonts" \
          "${ONLYOFFICE_PACKAGE_DIR}/fonts/" 2>/dev/null || true
fi

echo ""
echo "===== 第8步: 复制配置文件 ====="
if [ -d "${SCRIPT_DIR}/config" ]; then
    cp -r "${SCRIPT_DIR}/config/"* "${ONLYOFFICE_PACKAGE_DIR}/config/" 2>/dev/null || true
fi

if [ -f "${SCRIPT_DIR}/run-document-server.sh" ]; then
    cp "${SCRIPT_DIR}/run-document-server.sh" "${ONLYOFFICE_PACKAGE_DIR}/"
fi

if [ -d "${SCRIPT_DIR}/oracle" ]; then
    cp -r "${SCRIPT_DIR}/oracle" "${ONLYOFFICE_PACKAGE_DIR}/" 2>/dev/null || true
fi

echo ""
echo "===== 第9步: 构建 DocumentServer 镜像 ====="
docker build -f "${BUILD_TOOLS_DIR}/Dockerfile.documentserver" \
    -t onlyoffice-documentserver:custom \
    -t onlyoffice-documentserver:latest \
    "${ONLYOFFICE_PACKAGE_DIR}"

echo ""
echo "===== 第10步: 清理 ====="
docker rm -f onlyoffice-build 2>/dev/null || true
docker volume rm onlyoffice-build-data 2>/dev/null || true

echo ""
echo "=========================================="
echo "  编译打包完成!"
echo "=========================================="
echo ""
echo "运行 DocumentServer:"
echo "  docker run -d -p 80:80 -p 443:443 onlyoffice-documentserver:latest"
echo ""
echo "或使用 docker-compose:"
echo "  docker-compose -f docker-compose.yml up -d"
