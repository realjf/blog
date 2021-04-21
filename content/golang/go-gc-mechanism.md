---
title: "golang垃圾回收机制 Go Gc Mechanism"
date: 2021-04-21T11:23:18+08:00
keywords: ["golang"]
categories: ["golang"]
tags: ["golang"]
series: [""]
draft: true
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

## GC流程

### 1. GC执行扫描(sweep)终止
- stop the world（简称STW），这将导致所有P达到GC安全点
- 扫描所有未清扫的span，只有在以下情况下才会出现未扫描的span：此GC周期在预期时间之前被强制执行

### 2. GC执行标记(mark)阶段
- 通过将gcphase设置为_GCmark来准备标记阶段（来自_GCoff），启用写屏障，启用mutator协助和加入根标记作业。不得有物体扫描直到所有P都启用了写屏障，即使用STW完成。
- start the world，从这一点来说，GC工作是由调度器启动mark工人完成的，以及作为分配的一部分。写屏障屏蔽了重写指针和任何指针的新指针值写入（请参阅mbarrier.go 详细信息）。新分配的对象立即标记为黑色。
- GC执行根标记作业。这包括扫描所有堆栈，着色所有全局变量，着色中的所有堆指针堆外运行时数据结构。扫描堆栈停止goroutine，隐藏堆栈上的指针，然后恢复goroutine。
- GC将灰色对象的工作队列清空，扫描每个灰色对象变为黑色，并对对象中找到的所有指针进行着色（这反过来可能会将这些指针添加到工作队列）。
- 因为GC工作分布在本地缓存中，所以GC使用分布式终止算法，用于检测没有更多根标记作业或灰色对象（请参见gcMarkDone）。在这刻，GC转换到标记终止。

### 3. GC执行标记终止
- STW
- 将gcphase设置为_GCmarktermination，并禁用worker和辅助
- 执行像刷新mcaches一样的内务处理

### 4. GC执行扫描阶段
- 通过将gcphase设置为_GCoff来准备扫描阶段，设置扫描状态并禁用写屏障
- start the world。从这一刻开始，新分配的对象为白色，必要时在使用前分配扫描span
- GC在后台进行并发清除和在响应中进行分配

### 5. 完成足够的分配后，从上面的1重新开始清扫标记过程







