---
title: "golang垃圾回收机制 Go Gc Mechanism"
date: 2021-04-21T11:23:18+08:00
keywords: ["golang", "gc"]
categories: ["golang"]
tags: ["golang", "gc"]
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

## GC三色标记流程说明

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


## GC过程图解

![gc过程](/image/golang-gc.png)

1. 从根节点开始遍历对象，包括全局指针和goroutine栈上的指针
2. 标记（mark）阶段
  - 从根节点遍历到的对象标记为灰色，然后遍历灰色对象直至灰色队列为空
  - re-scan，重新扫描全局指针和栈上指针，因为mark和用户程序是并行的，所以在1过程中，可能会有新对象分配，这时需要写屏障记录下来，re-scan再重新检查一遍
3. STW有两次，分别是
  - GC将要开始的时候，这时主要做一些准备工作，比如启用写屏障等
  - 第二次就是在re-scan时候，如果这时没有STW，那么mark将无休止

其中：GCphase状态值在以下几个中转换

- _GCoff：gc关闭阶段
- _GCmark: gc标记清扫阶段
- _GCmarktermination：mark termination阶段

### 写屏障
假设开始的引用关系是：
```sh
root->A->B , root->A->C, root->D->E
```
在进行三色标记阶段，扫描了A对象，并标记A，这时，如果一个goroutine修改了D->E的引用关系为A->E，
此时是这样的：
```sh
root->A->B, root->A->C, root->A->E, root->D
```
出现这种情况，如何解决E的标记问题？写屏障就是记录下这一过程，并将E标记为存活状态，这样即使后面A->E的引用
关系解除，E也会在下一轮GC中被回收了。







**参考文献**

- [http://legendtkl.com/2017/04/28/golang-gc/](http://legendtkl.com/2017/04/28/golang-gc/)
- [https://mp.weixin.qq.com/s?__biz=MzUzMjk0ODI0OA==&mid=2247483727&idx=1&sn=abe1e6896cb398bde2517b469d07afa0&chksm=faaa3538cdddbc2e81e146f74fd7050a6ac9a89a13b024717c9d56888de4a19cb0973f6bbe94&mpshare=1&scene=24&srcid=04105l1DG5QXbS4dfUB6aWeX&key=fb1dd35c5489928a678ed39df498f0d7f7ce5ef29135addb7c0573a4d19220f05d9c2522d44eb6315eaa9b6590d1f3afaaf06a3e96a1abeb1fb22d2870f9185f446a1e704aa2b16bd0775cd7be370a43&ascene=14&uin=Mjg4MTE5ODIzMA%3D%3D&devicetype=Windows+10&version=62060739&lang=zh_CN&pass_ticket=bqbjocTiytbymxqE%2FkEqbcTWuMs1uh6W%2BK2eHz3sKwLI%2BWRx6of4k%2BmAlALLk8iH](https://mp.weixin.qq.com/s?__biz=MzUzMjk0ODI0OA==&mid=2247483727&idx=1&sn=abe1e6896cb398bde2517b469d07afa0&chksm=faaa3538cdddbc2e81e146f74fd7050a6ac9a89a13b024717c9d56888de4a19cb0973f6bbe94&mpshare=1&scene=24&srcid=04105l1DG5QXbS4dfUB6aWeX&key=fb1dd35c5489928a678ed39df498f0d7f7ce5ef29135addb7c0573a4d19220f05d9c2522d44eb6315eaa9b6590d1f3afaaf06a3e96a1abeb1fb22d2870f9185f446a1e704aa2b16bd0775cd7be370a43&ascene=14&uin=Mjg4MTE5ODIzMA%3D%3D&devicetype=Windows+10&version=62060739&lang=zh_CN&pass_ticket=bqbjocTiytbymxqE%2FkEqbcTWuMs1uh6W%2BK2eHz3sKwLI%2BWRx6of4k%2BmAlALLk8iH)