---
title: "如何切换多个版本的gcc编译器 How to Switch Between Multiple Gcc Compiler Versions"
date: 2020-11-28T20:22:22+08:00
keywords: ["linux", "gcc"]
categories: ["linux"]
tags: ["linux", "gcc"]
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


## 读完本节你将学到
- 如何安装多版本的gcc和g++编译器版本
- 如何创建可选的编译器版本列表
- 如何在多版本编译器间切换

## 软件要求
- gcc
- ubuntu

## 安装gcc
### 安装多个版本的gcc
```shell script
sudo apt-get install build-essential
sudo apt -y install gcc-7 g++-7 gcc-8 g++-8 gcc-9 g++-9
```

### 使用update-alternatives工具创建多版本gcc编译器可选列表
```shell script
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 7
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 7
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 8
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-8 8
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 9
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 9
```
> 最后一行的数字是优先级

### 检查c和c++编译器列表的可用性，并选择你期望的版本
```shell script
sudo update-alternatives --config gcc
There are 3 choices for the alternative gcc (providing /usr/bin/gcc).

  Selection    Path            Priority   Status
------------------------------------------------------------
  0            /usr/bin/gcc-9   9         auto mode
  1            /usr/bin/gcc-7   7         manual mode
* 2            /usr/bin/gcc-8   8         manual mode
  3            /usr/bin/gcc-9   9         manual mode
Press  to keep the current choice[*], or type selection number: 1
```
c++编译器如下：
```shell script
sudo update-alternatives --config g++
There are 3 choices for the alternative g++ (providing /usr/bin/g++).

  Selection    Path            Priority   Status
------------------------------------------------------------
* 0            /usr/bin/g++-9   9         auto mode
  1            /usr/bin/g++-7   7         manual mode
  2            /usr/bin/g++-8   8         manual mode
  3            /usr/bin/g++-9   9         manual mode

Press  to keep the current choice[*], or type selection number:
```

### 每次切换完版本后检查你选择的编译器版本
```shell script
$ gcc --version
$ g++ --version
```

### 要删除某一个版本
```shell script
sudo update-alternatives --remove gcc /usr/bin/gcc-5
```

### 如果在编译时遇到如下问题

#### 问题1
```shell script
usr/bin/ld: skipping incompatible /usr/lib/gcc/x86_64-linux-gnu/4.8/libgcc.a when searching for -lgcc
/usr/bin/ld: cannot find -lgcc
/usr/bin/ld: skipping incompatible /usr/lib/gcc/x86_64-linux-gnu/4.8/libgcc_s.so when searching for -lgcc_s
/usr/bin/ld: cannot find -lgcc_s
collect2: error: ld returned 1 exit status
```
解决方法
```shell script
sudo apt-get install gcc-multilib g++-multilib
```
> 注意，安装的gcc-multilib必须是对应gcc版本的如：gcc-4.8-multilib等

#### 问题2
```shell script
$ sudo make ARCH=i386 menuconfig
  HOSTCC  scripts/fixdep
/usr/bin/ld: cannot find crt1.o: No such file or directory
/usr/bin/ld: cannot find crti.o: No such file or directory
/usr/bin/ld: cannot find -lgcc_s
collect2: ld returned 1 exit status
make[1]: *** [scripts/fixdep] Error 1
make: *** [scripts] Error 2
```
解决方法
```shell script
sudo apt-get update
sudo apt-get install lib6-dev-i386
```
如果无效，采用如下方法
```shell script

```
