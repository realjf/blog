---
title: "如何安装QEMU模拟器 How to Install Qemu"
date: 2020-11-28T21:46:47+08:00
keywords: ["linux", "qemu"]
categories: ["linux"]
tags: ["linux", "qemu"]
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

QEMU是一套由法布里斯·贝拉(Fabrice Bellard)所编写的以GPL许可证分发源码的模拟处理器，在GNU/Linux平台上使用广泛。
Bochs，PearPC等与其类似，但不具备其许多特性，比如高速度及跨平台的特性，通过KQEMU这个闭源的加速器，QEMU能模拟至接近真实电脑的速度


## 从源码安装
```shell script
git clone https://git.qemu.org/git/qemu.git
cd qemu
git submodule init
git submodule update --recursive
./configure
make
```
## Linux

```shell script
apt-get install qemu
```

如果要使用如qemu-system-i386这样的命令，可以运行如下命令安装
```shell script
apt-get install qemu-system
```

[QEMU官网](https://download.qemu.org)

