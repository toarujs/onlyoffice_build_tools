#!/usr/bin/env python3

import sys
import os
sys.path.append('../../scripts')

import base

# Qt 下载源（按优先级尝试）
URLS = [
    "https://github.com/ONLYOFFICE-data/build_tools_data/raw/refs/heads/master/qt/",
    "https://gitee.com/toarujianshang/onlyoffice-build_tools_data/raw/master/qt/",
]

SYSROOTS = {
  "amd64": "qt_binary_5.9.9_gcc_64.7z",
  "arm64": "qt_binary_5.9.9_gcc_arm64.7z",
}

COMPILERS = {
  "amd64": "gcc_64",
  "arm64": "gcc_arm64",
}

def try_download(url, archive):
    """尝试从指定 URL 下载"""
    try:
        full_url = url + archive
        print(f"Trying: {full_url}")
        base.download(full_url, "./" + archive)
        
        # 验证下载的文件是否是有效的压缩包
        file_size = os.path.getsize("./" + archive)
        if file_size < 1000:  # 文件太小，可能是 HTML 错误页
            print(f"File too small ({file_size} bytes), likely error page")
            os.remove("./" + archive)
            return False
        return True
    except Exception as e:
        print(f"Failed: {e}")
        return False

def download_and_extract(name):
  cur_dir = os.getcwd()
  os.chdir("./qt_build/Qt-5.9.9")
  archive = SYSROOTS[name]
  folder = "./" + COMPILERS[name]
  if (base.is_dir(folder)):
    base.delete_dir(folder)
  archive_file = "./" + archive
  
  # 尝试多个源
  success = False
  for url in URLS:
    if try_download(url, archive):
      success = True
      break
  
  if not success:
    print("ERROR: All download sources failed!")
    print("Please download manually:")
    print(f"  qt_binary_5.9.9_gcc_64.7z -> place in {os.getcwd()}")
    sys.exit(1)
  
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
