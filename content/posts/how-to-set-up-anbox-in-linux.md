---
title: "linux下的安卓模拟器anbox安装 How to Set Up Anbox in Linux"
date: 2020-06-13T16:55:14+08:00
keywords: ["posts", "anbox"]
categories: ["posts"]
tags: ["posts", "anbox"]
series: [""]
draft: false
toc: false
related:
  threshold: 80
  includeNewer: false
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

### 环境准备
- kali linux 2020

### 开始
```shell script

# 使用下面的 PPA 来安装它
add-apt-repository ppa:morphis/anbox-support
apt update
apt install linux-headers-generic anbox-modules-dkms

# 在你安装 anbox-modules-dkms 软件包后，你必须手动重新加载内核模块，或需要系统重新启动
modprobe ashmem_linux
modprobe binder_linux

# 使用 APT-GET 命令 或 APT 命令 来安装 anbox
apt install anbox

# 否则，需要通过 snap 来进行安装
apt install snapd
snap install --classic anbox-install && anbox-installer
snap install --devmode --beta anbox
```

默认情况下，Anbox 并没有带有 Google Play Store。因此，我们需要手动下载每个应用程序（APK），并使用 Android 调试桥（ADB）安装它

```shell script
# 对于 Debian/Ubuntu 系统，使用 APT-GET 命令 或 APT 命令 来安装 ADB
apt install android-tools-adb
```

### 启动anbox container服务
```shell script
systemctl enable anbox-container-manager
systemctl start anbox-container-manager

# 期间如果遇到服务启动失败，可以查看对应的错误日志，可能是因为android.img文件不在/var/lib/anbox/android.img路径下，
# 可以通过https://build.anbox.io/android-images/2018/07/19/android_amd64.img 进行下载
# 或者如果安装了snap且安装来anbox，则可以通过复制/snap/anbox/current/android.img到对应目录/var/lib/anbox/下即可
```

### 通过anbox安装android应用
首先，你需要启动 ADB 服务
```shell script
# 列出可用模拟器设备
adb devices

# 安装语法
adb install yourapp.apk
```

需要下载安卓应用，可以通过以下应用市场下载

- https://www.apkmirror.com
- https://appgallery1.huawei.com













