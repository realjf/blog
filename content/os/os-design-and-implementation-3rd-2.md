---
title: "读书笔记——操作系统设计与实现第3版之二 进程 (Os Design and Implementation 3rd 2 —— process)"
date: 2020-11-09T17:53:45+08:00
keywords: ["os"]
categories: ["os"]
tags: ["os"]
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

## 进程介绍

### 进程模型
计算机上所有可运行的软件，包括操作系统，被组织成若干顺序进程，简称进程。
一个进程就是正在执行的程序，包括程序计数器、寄存器和变量的当前值。

一个进程包括程序、输入输出以及状态。


### 进程的创建
新进程都是由一个已经存在的进程执行了进程创建的系统调用而创建的。

创建进程使用fork系统调用，这个系统调用会创建一个与调用进程相同的副本，在调用了fork后，这两个进程（父进程和子进程）

- 拥有相同的内存映象
- 相同的环境字符串
- 相同的打开的文件描述符

子进程在创建之后会执行一个execve或者类似的系统调用，以修改其存储映象并运行一个新的程序，
在fork和execve调用之间，通常对标准输入文件、标准输出文件和标准错误文件等文件描述符进行操作

父进程和子进程拥有各自独立的地址空间，即某个进程在其地址空间修改数据对另一进程不可见。

> 可写的地址空间是不共享的，但是子进程有可能共享打开文件描述符之类的资源


### 进程的终止

### 进程的层次结构

- 再生服务器，启动或重启驱动和服务器，初始时处于阻塞状态，等待消息告诉它创建什么
- init进程，执行/etc/rc脚本，并向再生服务器发送命令启动引导映象中不存在的驱动和服务

### 进程的状态

- 运行态
- 就绪态
- 阻塞态

### 进程的实现

在操作系统中维持着一张进程表，每个进程占用一个进程表项（进程控制块），
一个进程控制块包含：

- 进程的状态
- 程序计数器
- 栈指针
- 内存分配状况
- 打开文件描述符状态
- 统计和调度信息
- 定时器和其他信号
- 进程由运行态到就绪态切换时所必须保存的其他信息



### 线程
在相同的地址空间中有多个控制流并行运行，就像它们是单独的进程一样，被称为线程。
或轻量进程。

线程有一个程序计数器，用来跟踪下一条指令，它有寄存器，存储当前使用的变量，当有堆栈，存储着执行的历史，
其中每一栈帧保存了没有返回的过程调用。

同样，线程也有一张线程表维护，每个线程独占一个表项，其内容包括

- 程序计数器
- 寄存器值及状态
- 堆栈
- 线程状态

## 进程间通信


### 竞争条件
两个多个进程读写某些共享数据，而最后的结果取决于进程运行的精确时序，称为竞争条件。

### 临界区
某些时候进程可能会访问共享内存或共享文件。对共享内存进行访问的程序片段称为临界区

临界区具有以下四个条件：

- 任何两个进程不能同时处于临界区
- 不应对cpu的速度和数目做任何假设
- 临界区外的进程不得阻塞其他进程
- 不得使进程在临界区外无休止的等待

### 忙等待互斥

- 关闭中断
- 锁变量
- 严格交替法
- Peterson解决方案
- TSL指令

### 睡眠和唤醒

- 生产者-消费者问题

### 信号量
一个信号量的值可以是0，表示没有积累下来的唤醒操作，或者为正值，表示有一个或多个被积累下来的唤醒操作

### 互斥
互斥是一个可以处于两态之一的变量：加锁和解锁，只需要一个二进制位表示。

### 管程
管程是由过程、变量及数据结构等组成的集合，他们组成一个特殊的模块或软件包。进程可以在任何需要时调用管程中的过程，
但它们不能在管程外的过程中直接访问管程内的数据结构。

任何时刻管程中只能有一个活跃进程。


### 消息传递

- 信箱，用来对一定数量的消息进程缓冲的地方
- 聚合原则，不适用缓冲，send在receive之前执行，则发送进程被阻塞，直到receive发送，执行receive时，消息直接从发送者复制到接受者。

## 经典IPC问题
- 哲学家进餐问题
- 读者-写者问题


## 进程调度
### 调度介绍
- 进程行为

#### 什么时候调度
- 当一个进程退出时
- 当一个进程在I/O或信号量上阻塞时

- 当一个新进程创建时
- 当一个I/O中断发生时
- 当一个时钟中断发生时


#### 调度算法的分类
- 批处理
- 交互式
- 实时

### 批处理系统中的调度
- 先到先服务
- 最短作业优先
- 最短剩余时间优先

#### 三级调度
- 准入调度器，决定哪些作业允许进入系统
- 内存调度器，决定了哪个进程留在内存而哪个进程换出到磁盘
- cpu调度器，在内存中选取下一个将要运行的进程

### 交互式系统中的调度
- 时间片轮转调度
- 优先级调度
- 多重队列
- 最短进程优先
- 保证调度算法
- 彩票调度算法，为进程发放针对系统各种资源的彩票，当调度器需要作出决策时，随机选择一张彩票，持有该彩票的进程将获得系统资源。
- 公平分享调度

### 实时系统调度
实时系统分为硬实时系统和软实时系统

### 策略和机制

### 线程调度
用户级线程和内核线程主要区别：

- 用户级线程进行线程切换只需要几条指令
- 内核线程需要完整的上下文切换，修改内存映射，使高速缓存失效
- 内核线程中的一个线程阻塞不会导致整个进程阻塞
- 用户线程下的则会导致整个线程阻塞


## MINIX 3 内部结构
![minix 3的四层结构](/image/minix_3.png)

- 第一层主要功能为上层驱动程序和服务器提供一组特权内核调用，这些调用由系统任务实现
- 第二层内的进程拥有最多的特权，第三层进程特权少一些，而第四层内的进程没有特权
- 第三层包含了服务器，即向用户进程提供有用服务的进程

#### 内核调用和POSIX系统调用
- 内核调用是由系统服务提供的以使驱动程序和服务器完成工作的低层函数
- POSIX系统调用是由POSIX规范定义的高层调用，这些调用供第四层的用户程序使用

- 第三层包含了服务器，即向用户进程提供有用的服务进程
- 进程管理器执行所有涉及启动或终止进程的minix3系统调用
- 文件系统负责执行文件系统的调用
- 信息服务器负责提供其他驱动程序和服务器的调试和状态信息的工作
- 再生服务器启动和重启哪些不与内核一起加载到内存的设备驱动程序
- 网络服务器
- 第2层和第三层内的驱动程序和服务器统称为系统进程，系统进程是操作系统的一部分。
- 第四层包括了所有的用户进程。
- 守护进程是周期性运行或总是等待某个事件的后台进程。

### MINIX 3中的进程管理

整个系统中所有的用户进程都属于以init为根节点的一棵进程树

#### MINIX 3的启动

##### 软盘启动
软盘第1道第一个扇区包含了引导程序，引导程序很小，因为它必须能容纳在一个扇区（512字节）里，
引导程序装入一个更大的程序boot，由boot装入操作系统
##### 硬盘启动
硬盘被分成若干分区，整个硬盘的第1个扇区包括一段小程序和磁盘分区表，通常两者合在一起称为主引导记录，
程序部分被执行以读入分区表并选择活动分区，活动分区的第一个扇区有一个引导程序，它随后被装入并执行以查找并启动程序boot，
它与从软盘引导完全相同


#### 进程树的初始化
![init进程加载进程](/image/init_process.png)

### MINIX 3中的进程间通信

### MINIX 3中的进程调度

## MINIX 3中的进程的实现
### MINIX 3源代码的组织

src目录下的include目录

include/目录包含了许多POSIX标准的头文件，包含三个子目录：

- sys/ 包含POSIX头文件
- minix/ 包含操作系统使用的头文件
- ibm/ 包含IBM PC特有定义的头文件


除src/include目录之外，src/目录还包含了其他三个重要的子目录，它们也包含了操作系统源码：

- kernel/ 第一层（调度、消息、时钟和系统任务）
- drivers/ 第二层（磁盘、控制台、打印机等的驱动程序）
- servers/ 第三层（进程管理器、文件系统、其他服务器）

还有另外三个源代码目录很重要：

- src/lib/ 库例程（如open，read）的源代码
- src/tools/ 用于构建MINIX3系统的Makefile和脚本
- src/boot/ 引导和安装MINIX 3的代码

除了进程管理器和文件系统源代码外，系统源程序目录src/servers/还包含了init程序和再生服务器rs的源代码

- 网络服务器的源代码在src/servers/inet/目录中
- src/drivers/目录包含设备驱动程序的源代码
- src/test/目录包含有一些被设计来对新编译好的MINIX 3系统进程完整测试的工具
- src/commands/目录包含大量命令，其中有工具程序的源代码

### 编译及运行MINIX 3
![内存加载分配情况](/image/memory-load.png)


### 公共头文件






































