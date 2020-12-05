---
title: "Fix Initramfs Uuid Does Not Exist"
date: 2020-12-05T14:23:09+08:00
keywords: ["linux"]
categories: ["linux"]
tags: ["linux", "initramfs"]
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

## 背景
我的系统是安装在raid10的磁盘阵列上的，由于之前磁盘写保护的问题，导致系统无法关机，于是我直接关电源，重启后，
能进入引导程序，之后却无法进入系统，停留在initramfs界面上，输入exit，提示是uuid 'xxxxx' does not exist

```shell script
# 查看磁盘阵列的情况
mdadm -D /dev/md0
# 显示的是磁盘阵列的所有工作设备全部状态显示为removed
# 我的磁盘工作设备包括：sdb1,sdc1,sdd1,sde1
# 空闲设备：sdf1 显示正在rebuilding
```

## 解决
```shell script
# 停止
mdadm --stop /dev/md0

# 重新恢复磁盘阵列
mdadm --assemble --run /dev/md0 /dev/{sdb1,sdc1,sdd1,sde1}
# 之后显示所有设备添加成功，重新查看磁盘阵列情况
mdadm -D /dev/md0
# 显示磁盘阵列已在工作中
exit
# 退出initramfs，并进入系统命令行模式，直接运行startx可以进入图形界面，或者直接运行cat /proc/mdstat可以查看当前的磁盘阵列同步情况
# 直到resync同步完成后，方可重启系统，一切恢复正常
```