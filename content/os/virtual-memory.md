---
title: "操作系统之虚拟内存 Virtual Memory"
date: 2020-04-26T16:40:51+08:00
keywords: ["虚拟内存"]
categories: ["os"]
tags: ["虚拟内存"]
series: [""]
draft: true
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

虚拟内存是计算机系统内存管理的一种技术。它使得应用程序认为它拥有连续的可用的内存（一个连续完整的地址空间），
而实际上，它通常是被分隔成多个物理内存碎片，还有部分暂时存储在外部磁盘存储器上，在需要时进行数据交换。


### 虚拟内存提供三个重要能力
- 将主存看成是一个存储在磁盘上的地址空间的高速缓存，在主存中只保存活动区域，并根据需要在磁盘和主存之间来回传送数据，通过这种方式，高效地使用了主存
- 为每个进程提供了一致的地址空间，从而简化了内存管理
- 保护了每个进程的地址空间不被其他进程破坏




