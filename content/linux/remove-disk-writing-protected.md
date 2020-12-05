---
title: "Remove Disk Writing Protected"
date: 2020-12-05T14:16:39+08:00
keywords: ["linux"]
categories: ["linux"]
tags: ["linux", "writing protected"]
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

## 背景介绍
最近新安装的磁盘阵列上的系统，老是出现写保护（writing protected）。

## 解决方法
使用hdparm命令可以解除写保护
```shell script
# 移除
hdparm -r0 <设备名>
# 如
hdparm -r0 /dev/sda1

/dev/sda1:
 setting readonly to 0 (off)
 readonly      =  0 (off)


# 更多命令
hdparm -h
```





