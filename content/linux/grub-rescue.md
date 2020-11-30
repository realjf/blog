---
title: "Grub Rescue no such partition"
date: 2020-11-30T08:58:27+08:00
keywords: ["linux", "mdadm"]
categories: ["linux"]
tags: ["linux", "mdadm", "磁盘阵列"]
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
我自己的系统是安装在5块磁盘组成的RAID5的磁盘阵列中的，其基本的组成如下：

- 4块激活磁盘
- 1块空闲磁盘

然后，今天突然想扩容下磁盘阵列，所以使用mdadm的--grow命令，把空闲磁盘加入到了激活磁盘数组里，
但是，没有重建数据，直接重启了，导致无法进入系统引导，并进入了grub rescue的界面，提示是：no such partition。

## 解决
准备一个u盘可引导设备，进入系统，然后进行数据重建，以便让空闲磁盘真正加入到磁盘阵列的工作设备数组中。

```shell script
# 查看当前设备
lsblk 

# 确认之前都是raid成员设备的设备号，我这里是sdb1,sdc1,sdd1,sde1,sdf1
# 然后重建磁盘阵列数据
mdadm --create /dev/md0 --verbose --raid-devices=5 --level=5 /dev/sd{b,c,d,e,f}1

# 然后查看构建进度
cat /proc/mdstat

# 查看当前磁盘阵列状态
mdadm -D /dev/md0

# 等待rebuiding完成后即可重启进入系统
```

- --create：创建模式
- --verbose: 显示信息
- --raid-devices：设置active devices设备数
- --level: 设置RAID级别，如raid0,0,raid1,1,raid5,5,raid10,10等
- --space-devices: 设置空闲设备数
