---
title: "如何为linux内核增加其他cpu架构支持 How to Add Other Architecture"
date: 2020-11-28T21:09:06+08:00
keywords: ["linux", "architecture"]
categories: ["linux"]
tags: ["linux", "architecture"]
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

### 添加其他架构软件安装支持
```shell script
sudo dpkg --add-architecture i386
sudo apt-get update
sudo-get upgrade
sudo-get dist-upgrade
```

### 移除某个架构
```shell script
sudo dpkg --remove-architecture i386
```




