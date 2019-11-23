---
title: "unix环境高级编程 之 apue.h环境安装配置 "
date: 2019-11-23T09:20:03+08:00
keywords: ["unix", "unix环境高级编程"]
categories: ["unix"]
tags: ["unix", "unix环境高级编程"]
draft: false
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

官网[http://www.apuebook.com/apue3e.html](http://www.apuebook.com/apue3e.html)

### 准备
```shell script
apt-get install libbsd-dev
```
如果不执行上面步骤可能会出现如下问题：
```shell script
barrier.c:(.text+0x6e): undefined reference to `heapsort’
collect2: ld
make[1]: *** [barrier] 
make[1]: Leaving directory `/home/albert/Documents/progs/apue.3e/threads’
make: *** [all] 
```

### 1. 下载解压
```shell script
wget http://www.apuebook.com/src.3e.tar.gz
tar zxvf src.3e.tar.gz
cd apue.3e
make
```
### 2. 复制相关头文件到/usr/include等
```shell script
cp ./include/apue.h /usr/include
cp ./lib/libapue.a /usr/local/lib
```
### 3. 搭建成功，测试
```shell script
gcc 1-3.c -o 1-3 -lapue
# 编译连接后
./1-3 /lib
# 查看是否正常执行程序
```

