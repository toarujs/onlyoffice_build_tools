#!/usr/bin/env python

import sys
sys.path.append('../../scripts')
import base
import os
import subprocess
import deps
import qt_binary_build

# Qt 下载源配置
QT_MIRROR_ENV = os.environ.get("QT_MIRROR", "")

QT_URLS = {
    "default": "https://github.com/ONLYOFFICE-data/build_tools_data/raw/refs/heads/master/qt/qt-everywhere-opensource-src-5.9.9.tar.xz",
    "gitee": "https://gitee.com/toarujianshang/build-tools-data/raw/master/qt/qt-everywhere-opensource-src-5.9.9.tar.xz",
    "ustc": "https://mirrors.ustc.edu.cn/qtproject/official_releases/qt/5.9/5.9.9/single/qt-everywhere-opensource-src-5.9.9.tar.xz",
    "tsinghua": "https://mirrors.tuna.tsinghua.edu.cn/qt/official_releases/qt/5.9/5.9.9/single/qt-everywhere-opensource-src-5.9.9.tar.xz",
}

def get_qt_url():
    if QT_MIRROR_ENV:
        return QT_MIRROR_ENV
    return QT_URLS["ustc"]  # 默认使用中科大镜像

def get_branch_name(directory):
  cur_dir = os.getcwd()
  os.chdir(directory)
  command = "git symbolic-ref --short -q HEAD"
  current_branch = base.run_command(command)['stdout']
  os.chdir(cur_dir)
  return current_branch

def install_qt():
  qt_url = get_qt_url()
  print(f"Downloading Qt from: {qt_url}")
  
  if not base.is_file("./qt_source_5.9.9.tar.xz"):
    base.download(qt_url, "./qt_source_5.9.9.tar.xz")

  if not base.is_dir("./qt-everywhere-opensource-src-5.9.9"):
    base.cmd("tar", ["-xf", "./qt_source_5.9.9.tar.xz"])

  qt_params = ["-opensource",
               "-confirm-license",
               "-release",
               "-shared",
               "-accessibility",
               "-prefix",
               "./../qt_build/Qt-5.9.9/gcc_64",
               "-qt-zlib",
               "-qt-libpng",
               "-qt-libjpeg",
               "-qt-xcb",
               "-qt-pcre",
               "-no-sql-sqlite",
               "-no-qml-debug",
               "-gstreamer", "1.0",
               "-nomake", "examples",
               "-nomake", "tests",
               "-skip", "qtenginio",
               "-skip", "qtlocation",
               "-skip", "qtserialport",
               "-skip", "qtsensors",
               "-skip", "qtxmlpatterns",
               "-skip", "qt3d",
               "-skip", "qtwebview",
               "-skip", "qtwebengine"]

  base.cmd_in_dir("./qt-everywhere-opensource-src-5.9.9", "./configure", qt_params)
  base.cmd_in_dir("./qt-everywhere-opensource-src-5.9.9", "make", ["-j", "4"])
  base.cmd_in_dir("./qt-everywhere-opensource-src-5.9.9", "make", ["install"])
  return
  
def install_qt_prebuild():
  base.cmd("python3", ["qt_binary_fetch.py", "all"])
  return

if not base.is_file("./node_js_setup_14.x"):
  print("install dependencies...")
  deps.install_deps()

if not base.is_dir("./qt_build"):
  print("install qt...")
  if base.get_env("DO_NOT_USE_PREBUILD_QT") == "1":
    qt_binary_build.install_qt()
  else:
    install_qt_prebuild()

branch = get_branch_name("../..")

array_args = sys.argv[1:]
array_modules = []
params = []

config = {}
for arg in array_args:
  if (0 == arg.find("--")):
    indexEq = arg.find("=")
    if (-1 != indexEq):
      config[arg[2:indexEq]] = arg[indexEq + 1:]
      params.append(arg[:indexEq])
      params.append(arg[indexEq + 1:])
  else:
    array_modules.append(arg)

if ("branch" in config):
  branch = config["branch"]

print("---------------------------------------------")
print("build branch: " + branch)
print("---------------------------------------------")

modules = " ".join(array_modules)
if "" == modules:
  modules = "desktop builder server"

print("---------------------------------------------")
print("build modules: " + modules)
print("---------------------------------------------")

build_tools_params = ["--branch", branch, 
                      "--module", modules, 
                      "--update", "1",
                      "--qt-dir", os.getcwd() + "/qt_build/Qt-5.9.9"] + params

base.cmd_in_dir("../..", "./configure.py", build_tools_params)
base.cmd_in_dir("../..", "./make.py")
