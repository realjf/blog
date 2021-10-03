---
title: "GDNative Cpp Setup"
date: 2021-10-03T14:54:32+08:00
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

GDNative的C++绑定构建在NativeScript GDNative API之上, 并提供了一种使用C++在Godot中 "扩展" 节点的更好方法. 这相当于在GDScript中编写脚本C++脚本

godot 3.1新增了NativeScript 1.1，使GDNative能够构建更好的c++绑定库。如果您想编写一个也支持godot 3.0的c++ gdnative插件，您需要使用3.0分支和nativescript 1.0语法。

### 准备
- godot 3.x可执行文件
- python环境
- 一个c++编译器
- scons作为构建工具
- godot-cpp 仓库的副本

### 下载安装
#### 安装scons
提前安装好python，然后
从https://www.scons.org/下载最新版本的源码包，然后解压，之后在解压目录下运行如下命令：
```sh
python setup.py install
```
安装SCons位于/usr/local/bin或 C:\Python39\Scripts，同时安装使用SCons在Python的构建依赖库/usr/local/lib/scons或C:\Python39\scons。


#### 构建c++绑定
```sh
mkdir gdnative_cpp_example
cd gdnative_cpp_example
git init
git submodule add https://github.com/godotengine/godot-cpp
cd godot-cpp
git submodule update --init
```
当然，你也可以直接下载godot-cpp和godot_headers
> godot-cpp 现在包含 godot_headers 作为嵌套子模块, 如果您手动下载它们, 请确保将 godot_headers 放在 godot-cpp 文件夹中.

使用scons生成c++绑定
```sh
cd godot-cpp
scons platform=windows generate_bindings=yes bits=64 -j8 target=release
cd ..
```
- j8 可以加快编译速度，8表示您系统中cpu的线程数，cpu线程数可以通过任务管理器查看
- platform 可以是windows、linux、osx
- bits 表示位数
- target可以是release、debug

这一步完成后，您应该有一个静态库，可以编译到您的项目中，存储在godot-cpp/bin/目录中

### 创建一个简单的插件
首先创建一个空的godot项目，我们将在其中放置一些文件

打开godot并创建一个新项目，将项目放置在gdnative模块的文件结构中，命名为demo的文件夹中

创建一个main节点的场景，将其保存为main.tscn。
回到顶级GDNative模块文件夹，我们创建一个







