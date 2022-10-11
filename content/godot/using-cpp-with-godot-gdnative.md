---
title: "Using Cpp With Godot Gdnative"
date: 2022-10-11T09:55:35+08:00
keywords: ["godot"]
categories: ["godot"]
tags: ["godot"]
series: [""]
draft: true
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

## 准备
- debian系统
- vscode
- godot
- git

首先查看需要安装的系统依赖[https://godot-doc.readthedocs.io/en/3.0/development/compiling/compiling_for_x11.html#](https://godot-doc.readthedocs.io/en/3.0/development/compiling/compiling_for_x11.html#)

```sh
# 安装依赖
sudo apt-get install build-essential scons pkg-config libx11-dev libxcursor-dev libxinerama-dev \
    libgl1-mesa-dev libglu-dev libasound2-dev libpulse-dev libfreetype6-dev libssl-dev libudev-dev \
    libxi-dev libxrandr-dev
```
然后下载[godot-cpp项目](https://github.com/godotengine/godot-cpp)
```sh
git clone --recursive https://github.com/godotengine/godot-cpp -b 3.x
```
然后是编译项目
```sh
# 该存储库包含当前 Godot 版本的元数据副本，但如果您需要为较新版本的 Godot 构建这些绑定，只需调用 Godot 可执行文件：
godot --gdnative-generate-json-api api.json
# 然后把api.json文件放入godot-cpp项目下，然后使用use_custom_api_file=yes custom_api_file=api.json运行scons命令即可
cd godot-cpp
scons generate_bindings=yes bits=64
# 当然编译也可以加上platform=windows/linux/macos/android/ios/javascript选项，同时还可以使用-jN指定使用CPU核心数
```
当编译完成，您应该有可以在 godot-cpp/bin/ 中找到对应的静态库xxx.a文件

## 现在可以使用你编译的静态库文件了

然后下载[gdnative-cpp-example项目](https://github.com/BastiaanOlij/gdnative_cpp_example)
```sh
git clone --recursive git@github.com:BastiaanOlij/gdnative_cpp_example.git
```

