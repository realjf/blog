---
title: "debian 系统启动进入Busybox Initramfs界面"
date: 2020-02-20T22:07:19+08:00
keywords: ["busybox", "initramfs"]
categories: ["linux"]
tags: ["busybox", "initramfs"]
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

### 首先说下背景
- 系统环境： debian 9


##### 问题描述1
今天使用vmware workstation的时候，提示操作失败，且提示为文件系统只读。
奇怪？怎么突然进入可读了，猜想可能文件系统哪里损坏导致进入只读保护模式。

所以重新启动，之后进入了busybox界面的Initramfs界面，输入help可以查看相应命令。
我使用exit直接退出看能否重新进入，发现还是提示错误，无法进入

> busybox可以提供一个比较完善的shell工具集以及运行环境，同时可以引导程序进入系统。

##### 解决
在多次尝试重启无果后，重新查看错误提示，提到了/dev/mapper/realjf--vg-root的文件系统，
可能是文件系统损坏了，所以开始检查修复文件系统：fsck /dev/mapper/realjf--vg-root，
然后系统开始检查文件系统损坏情况，并尝试进行修复，多次输入'y'后，提示文件系统修复完成，
然后重新输入exit看是否能重新进入系统，发现已经可以进入系统了。

##### 问题描述2
```shell script
Gave up waiting for root device. Common problems:
    - Boot args (cat /proc/cmdline)
    - Check rootdelay=(did the system wait for the right device ?)
    - Missing modules (cat /proc/modules; ls /dev)

ALERT! /dev/mapper/realjf--vg-root does not exist.

Dropping to a shell!

BusyBox v.1.23.2 (Debian xxx. xxx) built-in shell (ash)
Enter 'help' for list of built-in commands.

(initramfs):
```

##### 解决方法1
在该命令行下运行如下命令
```shell script
lvm vgchange -a y
exit
```
然后运行如下命令
```shell script
update-initramfs -k all -c
# 运行结束后，重启即可
```
##### 解决方法2
执行以下命令
```shell script
#停止设备
mdadm -S /dev/md0
#激活设备
mdadm -A -s /dev/md0
#强制启动
mdadm -R /dev/md0
# 退出
exit
```

