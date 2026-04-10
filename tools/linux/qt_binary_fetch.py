#!/usr/bin/env python3

import sys
import os
sys.path.append('../../scripts')

import base

# Qt 下载源配置
# 可通过环境变量 QT_MIRROR 指定
QT_MIRROR_ENV = os.environ.get("QT_MIRROR", "")

URLS = {
    "default": "https://github.com/ONLYOFFICE-data/build_tools_data/raw/refs/heads/master/qt/",
    "gitee": "https://gitee.com/toarujianshang/build-tools-data/raw/master/qt/",
    "ustc": "https://mirrors.ustc.edu.cn/qtproject/official_releases/qt/5.9/5.9.9/single/",
    "tsinghua": "https://mirrors.tuna.tsinghua.edu.cn/qt/official_releases/qt/5.9/5.9.9/single/",
}

def get_url():
    if QT_MIRROR_ENV:
        return QT_MIRROR_ENV
    return URLS["ustc"]  # 默认使用中科大镜像

URL = get_url()

SYSROOTS = {
  "amd64": "qt_binary_5.9.9_gcc_64.7z",
  "arm64": "qt_binary_5.9.9_gcc_arm64.7z",
}

COMPILERS = {
  "amd64": "gcc_64",
  "arm64": "gcc_arm64",
}

def download_and_extract(name):
  cur_dir = os.getcwd()
  os.chdir("./qt_build/Qt-5.9.9")
  archive = SYSROOTS[name]
  folder = "./" + COMPILERS[name]
  if (base.is_dir(folder)):
    base.delete_dir(folder)
  archive_file = "./" + archive
  print(f"Downloading Qt from: {URL + archive}")
  base.download(URL + archive, archive_file)
  base.extract(archive_file, "./")
  os.chdir(cur_dir)
  base.setup_local_qmake("./qt_build/Qt-5.9.9/" + COMPILERS[name] + "/bin")

def main():
  if len(sys.argv) != 2:
    print("Usage: fetch.py [amd64|arm64|all]")
    sys.exit(1)

  target = sys.argv[1]

  if not base.is_dir("./qt_build/Qt-5.9.9"):
    base.create_dir("./qt_build/Qt-5.9.9")

  targets = []
  if ("all" == target):
    targets.append("amd64")
    targets.append("arm64")
  elif ("arm64" == target) and not base.is_os_arm():
    targets.append("amd64")
    targets.append(target)
  else:
    targets.append(target)

  if (0 == len(targets)):
    print(f"Unknown target: {target}")
    print("Valid values: amd64, arm64, all")
    sys.exit(1)

  for name in targets:
    download_and_extract(name)

  if "arm64" in targets and not base.is_os_arm():
    base.move_dir("./qt_build/Qt-5.9.9/gcc_arm64/bin", "./qt_build/Qt-5.9.9/gcc_arm64/_bin")
    base.copy_dir("./qt_build/Qt-5.9.9/gcc_64/bin", "./qt_build/Qt-5.9.9/gcc_arm64/bin")

if __name__ == "__main__":
    main()
