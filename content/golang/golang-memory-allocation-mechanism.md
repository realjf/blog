---
title: "golang内存分配机制(Golang Memory Allocation Mechanism)"
date: 2021-04-14T11:40:54+08:00
keywords: ["golang"]
categories: ["golang"]
tags: ["golang", "golang内存分配"]
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
menu:
  docs:
    title: ""
    parent: "golang"
    weight: 130

---

### 环境
- golang v1.16.3
- 64位系统


### 分配器描述
golang内存分配器原理与tcmalloc类似，通过维护一块大的全局内存，每个线程（golang中的P）维护一块小的私有内存，私有内存不足再从全局申请。

主分配器工作在页面运行时，较小的分配大小（_MaxSmallSize = 32 << 10, 不超过32kb）是四舍五入到大约70个()尺寸的class，每个class有自己的一组大小正好相同的objects，任何空闲的内存都可以分割成一组其中一个class尺寸的objects，然后使用位图(bitmap)进行管理

### 虚拟内存布局
- 堆由一组arenas组成，这些arenas在64位上是64MB，而32位上是4MB，每个arena的起始地址也是与该arena的大小一致（由此可知其地址空间是从高位到低位）
- 每个arena都有一个关联的heapArena对象来存储该arena的元数据：arena上的所有words的堆bitmap以及arena上所有pages的span映射。heapArena对象是他们自己被分配到堆外。
- 因为arenas是对齐的，所以地址空间可以被视为一系列arena框架。arena 映射（mheap_.arenas）将从arena帧编号映射到*heapArena，或者对于go堆不支持的地址空间的部分区域，映射为0,。arena 映射是由“L1”arena 映射和许多“L2”arena 映射组成的两级数组；然而，由于arena是巨大的，在许多架构中，arena 映射由一个大的“L2”map组成
- arena 映射覆盖了整个可能的地址空间，允许go堆使用地址空间的任何部分。分配器试图保持arena的连续性，以便大spans能穿过arenas

### 分配器的数据结构
- fixalloc: 用于固定大小堆外objects的空闲列表分配器，用于管理分配器使用的存储
- mheap: malloc堆，以page(8192字节)粒度管理
- mspan: 由mheap管理的一系列正在使用的page
- mcentral: 收集所有给定尺寸的class的spans
- mcache: 一个具有可用空间的mspan的per-P(每个线程P)的缓存
- mstats: 分配统计信息





### 分配流程

#### 分配的对象：
 - 微小对象：小于16B
 - 一般小对象：16B ~ 32KB
 - 大对象：大于32KB
#### 分配方式
- 微小对象：由微型分配器分配
- 小对象：按照计算尺寸大小，然后使用mcache中mspan对应class大小的块分配
- 大对象：直接通过mheap分配，申请需要消耗全局锁锁定代价，任何时间点只能有一个P申请

#### 分配一个小object将沿着缓存的层次结构进行
1. 四舍五入到一个小尺寸class，在这个线程P的mcache中查看相应的mspan，扫描mspan的空闲bitmap以查找空闲slot，如果有空闲的slot，则分配给它，这一切都可以在不获取锁的情况下完成
2. 如果mcache中的mspan没有空闲slot，则从mcentral的符合尺寸class要求的有空闲空间的mspan中，获取新的mspan，获得一个完整span将分摊锁定mcentral的成本
3. 如果mcentral的mspan列表为空，则从mheap中获取一个运行时page，用于这个mspan
4. 如果mheap为空，或没有足够大的运行时page，则从操作系统中分配一组新的pages(至少1MB)，分配一个大的运行时page分摊与操作系统通信的成本

#### 扫描一个mspan并释放其上的objects，处理起来的类似层次结构
1. 如果正在扫描mspan以响应分配，则返回到mcache以满足分配
2. 否则，如果mspan中仍有已分配的object，根据mspan的class的大小，将它放在mcentral空闲列表中
3. 否则，如果mspan中的所有objects都是空闲的，则mspan的pages将被返回到mheap，这时这个mspan就结束生命周期了

#### 分配一个大object
分配和释放大object使用mheap，直接绕过mcache和mcentral


**参考文献**

- [译文：Go 内存分配器可视化指南](https://www.linuxzen.com/go-memory-allocator-visual-guide.html)
- [Go's Memory Allocator - Overview](https://andrestc.com/post/go-memory-allocation-pt1/)
- [图解Go语言内存分配](https://juejin.cn/post/6844903795739082760)
- [Go 1.5 源码剖析](https://github.com/qyuhen/book)
- [图解golang的内存分配](https://www.cnblogs.com/shijingxiang/articles/12196677.html)
- [深入理解GO语言之内存详解](https://juejin.cn/post/6844903506948669447)
- [探索Go内存管理(分配)](https://www.jianshu.com/p/47691d870756)