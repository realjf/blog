---
title: "Golang 并发编程 之 sync.Mutex 或 channel（通道）"
date: 2019-11-21T18:01:02+08:00
keywords: ["golang", "concurrency"]
categories: ["golang"]
tags: ["golang", "concurrency"]
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
---

并发控制中sync.Mutex 与 channel 的使用？
===

go的创建者建议“通过通信共享内存，不通过共享内存进行通信”。

也就是说，Go确实在sync包中提供了传统的锁定机制。大多数锁定问题可以使用通道锁定或传统锁定来解决

#### 使用锁机制和通道的优劣分析
Go新手常见的错误是仅仅因为可能和/或很有趣而过度使用通道和goroutine。如果最适合您的问题，请不要害怕使用sync.Mutex。
Go务实的做法是让您使用能够最好地解决问题的工具，而不用强迫您使用一种代码风格.

通常

| channel | mutex |
| ----| ----|
| 相互传递数据，分发工作单元，传递异步结果 | 缓存，状态|


### wait-group
另一个重要的同步机制是sync.WaitGroup。
这允许多个协作goroutine在再次独立运行之前共同等待同一个阈值事件。


通常在两种情况下很有用。

- 在“清理”时，可以使用sync.WaitGroup来确保所有goroutine（包括主要的goroutine）都在完全终止之前等待
- 更常见的情况是循环算法，其中涉及一组goroutine，这些goroutine全部独立工作一段时间，然后全部等待障碍，然后再次独立进行。此模式可能会重复很多次。障碍事件可能会交换数据。此策略是批量同步并行（BSP）的基础


### 结语
怎么使用取决于你的应用场景，通道通信，互斥锁和等待组是互补的，可以组合使用。