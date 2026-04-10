#!/bin/bash

# 使用以下顺序尝试下载：
# 1. Gitee raw
# 2. GitHub raw (需要代理或 hosts 修改)
# 3. 直接从网络搜索

echo "Downloading Python3..."

# 尝试从 Gitee 下载
if ! wget --quiet --speding https://gitee.com/toarujianshang/onlyoffice-build_tools_data/raw/master/python/python3.tar.gz -O python3.tar.gz 2>/dev/null; then
    echo "Gitee download failed, trying alternative..."
    
    # 备选：从 GitHub 下载（如果可以访问）
    if wget --quiet https://github.com/ONLYOFFICE-data/build_tools_data/raw/refs/heads/master/python/python3.tar.gz -O python3.tar.gz 2>/dev/null; then
        echo "Downloaded from GitHub"
    else
        echo "Both sources failed. Please download manually:"
        echo "1. Visit: https://gitee.com/toarujianshang/onlyoffice-build_tools_data/tree/master/python"
        echo "2. Download python3.tar.gz"
        echo "3. Place it in: $(pwd)"
        exit 1
    fi
fi

if ! wget --quiet https://gitee.com/toarujianshang/onlyoffice-build_tools_data/raw/master/python/extract.sh -O extract.sh 2>/dev/null; then
    wget --quiet https://github.com/ONLYOFFICE-data/build_tools_data/raw/refs/heads/master/python/extract.sh -O extract.sh 2>/dev/null
fi

chmod +x ./extract.sh
./extract.sh

cd ./python3/bin
ln -s python3 python
cd ../../
rm ./extract.sh
rm ./python3.tar.gz
