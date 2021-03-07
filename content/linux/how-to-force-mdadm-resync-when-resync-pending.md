---
title: "当mdadm查看磁盘阵列出现state为resync(Pending)时如何处理？ How to Force Mdadm Resync When Resync Pending"
date: 2021-03-07T11:16:03+08:00
keywords: ["linux","mdadm"]
categories: ["linux"]
tags: ["linux","mdadm"]
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

### 查看情况
```sh
cat /proc/mdstat

ersonalities : [linear] [multipath] [raid0] [raid1] [raid6] [raid5] [raid4] [raid10] 
md0 : active raid10 sdb1[0] sdf1[4](S) sde1[3] sdd1[2] sdc1[1]
      3906762752 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]
      resync=PENDING
      bitmap: 10/30 pages [40KB], 65536KB chunk

unused devices: <none>

```

解决方案时强制repair或resync
```sh
echo "repair" > /sys/block/md0/md/sync_action
```




