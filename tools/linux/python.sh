#!/bin/bash

wget https://gitee.com/toarujianshang/onlyoffice-build_tools_data/raw/master/python/python3.tar.gz
wget https://gitee.com/toarujianshang/onlyoffice-build_tools_data/raw/master/python/extract.sh

chmod +x ./extract.sh
./extract.sh

cd ./python3/bin
ln -s python3 python
cd ../../
rm ./extract.sh
rm ./python3.tar.gz
