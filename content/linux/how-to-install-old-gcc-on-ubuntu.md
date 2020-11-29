---
title: "如何安装低版本的gcc How to Install Old Gcc on Ubuntu"
date: 2020-11-28T21:02:00+08:00
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


## 提供如下gcc版本
```shell script
# provides
# lucid
/usr/bin/gcc-3.3
/usr/bin/g++-3.3
/usr/bin/gcc-3.4
/usr/bin/g++-3.4
/usr/bin/gcc-4.0
/usr/bin/g++-4.0
/usr/bin/gcc-4.1
/usr/bin/g++-4.1
/usr/bin/gcc-4.2
/usr/bin/g++-4.2
# precise
/usr/bin/gcc-3.3
/usr/bin/g++-3.3
/usr/bin/gcc-4.5
/usr/bin/g++-4.5
# trusty
/usr/bin/gcc-3.3
/usr/bin/g++-3.3
/usr/bin/gcc-4.5
/usr/bin/g++-4.5
```

## 安装
```shell script
# get old gcc, compiler tools only ...
sudo add-apt-repository ppa:h-rayflood/gcc-lower
sudo apt-get update
sudo apt-get dist-upgrade 
sudo apt-get install gcc-N.N
sudo apt-get install g++-N.N
```

- update：当执行apt-get update时，update重点更新的是来自软件源的软件包的索引记录（即index files）
- upgrade: 当执行apt-get upgrade时，upgrade是根据update更新的索引记录来下载并更新软件包，在以下几种情况，某个待升级的软件包不会被升级。
    - 新软件包和系统的某个软件包有冲突
    - 新软件包有新的依赖，但系统不满足依赖
    - 安装新软件包时，要求先移除旧的软件包
- dist-upgrade: 当执行apt-get dist-upgrade时，除了拥有upgrade的全部功能外，dist-upgrade会比upgrade更智能地处理需要更新的软件包的依赖关系
    - 可以智能处理新软件包的依赖
    - 智能冲突解决系统
    - 安装新软件包时，可以移除旧软件包，但不是所有软件都可以
- full-upgrade：在执行full-upgrade 之前也要先执行update ，升级整个系统，必要时可以移除旧软件包

