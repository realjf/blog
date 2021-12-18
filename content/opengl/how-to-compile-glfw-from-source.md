---
title: "如何从源码构建GLFW How to Compile Glfw From Source"
date: 2020-01-23T00:47:53+08:00
keywords: ["opengl"]
categories: ["opengl"]
tags: ["opengl"]
series: [""]
draft: false
toc: false
related:
  threshold: 50
  includeNewer: true
  toLower: false
  indices:
  - name: keywords
    weight: 100
  - name: tags
    weight: 90
  - name: categories
    weight: 50
  - name: date
    weight: 10
---

## 首先glfw下载
https://www.glfw.org/download.html

下载源码包后，开始安装

- 环境：debian-10

## 构建
```sh
unzip glfw-3.3.2.zip

mkdir glfw-build

cd glfw-build

cmake ..
```
报错如下：
```sh
-- The C compiler identification is GNU 10.2.0
-- Detecting C compiler ABI info
-- Detecting C compiler ABI info - done
-- Check for working C compiler: /usr/bin/cc - skipped
-- Detecting C compile features
-- Detecting C compile features - done
-- Looking for pthread.h
-- Looking for pthread.h - found
-- Performing Test CMAKE_HAVE_LIBC_PTHREAD
-- Performing Test CMAKE_HAVE_LIBC_PTHREAD - Failed
-- Looking for pthread_create in pthreads
-- Looking for pthread_create in pthreads - not found
-- Looking for pthread_create in pthread
-- Looking for pthread_create in pthread - found
-- Found Threads: TRUE  
-- Found Doxygen: /usr/bin/doxygen (found version "1.8.20") found components: doxygen 
-- Using X11 for window creation
-- Found X11: /usr/include   
-- Looking for XOpenDisplay in /usr/lib/x86_64-linux-gnu/libX11.so;/usr/lib/x86_64-linux-gnu/libXext.so
-- Looking for XOpenDisplay in /usr/lib/x86_64-linux-gnu/libX11.so;/usr/lib/x86_64-linux-gnu/libXext.so - found
-- Looking for gethostbyname
-- Looking for gethostbyname - found
-- Looking for connect
-- Looking for connect - found
-- Looking for remove
-- Looking for remove - found
-- Looking for shmat
-- Looking for shmat - found
-- Looking for IceConnectionNumber in ICE
-- Looking for IceConnectionNumber in ICE - found
CMake Error at CMakeLists.txt:206 (message):
  RandR headers not found; install libxrandr development package


-- Configuring incomplete, errors occurred!
See also "/opt/shared/vscode_projects/glfw-3.3.2/glfw-build/CMakeFiles/CMakeOutput.log".
See also "/opt/shared/vscode_projects/glfw-3.3.2/glfw-build/CMakeFiles/CMakeError.log".
```
#### 解决
```sh
apt-get install libxrandr-dev -y
```
#### 报错
```sh
-- Using X11 for window creation
CMake Error at CMakeLists.txt:211 (message):
  Xinerama headers not found; install libxinerama development package


-- Configuring incomplete, errors occurred!
See also "/opt/shared/vscode_projects/glfw-3.3.2/glfw-build/CMakeFiles/CMakeOutput.log".
See also "/opt/shared/vscode_projects/glfw-3.3.2/glfw-build/CMakeFiles/CMakeError.log".
```
#### 解决
```sh
apt-get install libxinerama-dev -y
```
#### 报错
```sh
-- Using X11 for window creation
CMake Error at CMakeLists.txt:221 (message):
  Xcursor headers not found; install libxcursor development package


-- Configuring incomplete, errors occurred!
See also "/opt/shared/vscode_projects/glfw-3.3.2/glfw-build/CMakeFiles/CMakeOutput.log".
See also "/opt/shared/vscode_projects/glfw-3.3.2/glfw-build/CMakeFiles/CMakeError.log".
```
#### 解决
```sh
apt-get install libxcursor-dev -y
```
#### 报错
```sh
-- Using X11 for window creation
CMake Error at CMakeLists.txt:226 (message):
  XInput headers not found; install libxi development package


-- Configuring incomplete, errors occurred!
See also "/opt/shared/vscode_projects/glfw-3.3.2/glfw-build/CMakeFiles/CMakeOutput.log".
See also "/opt/shared/vscode_projects/glfw-3.3.2/glfw-build/CMakeFiles/CMakeError.log".
```

#### 解决
```sh
apt-get install libxi-dev -y
```

#### 最后构建成功
```sh
# 构建静态库
cmake ..
-- Using X11 for window creation
-- Configuring done
-- Generating done
-- Build files have been written to: /opt/shared/vscode_projects/glfw-3.3.2/glfw-build

# 构建动态库
cmake -DBUILD_SHARED_LIBS=ON ..
```

## 安装
```sh
make && make install
```



