---
title: "Golang调度策略 Golang Scheduling Policy"
date: 2021-04-05T22:32:42+08:00
keywords: ["golang"]
categories: ["golang"]
tags: ["golang"]
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

### go运行调度策略
![go运行调度策略](/image/golang_scheduling_policy.png)

- P包含了运行G所需的上下文资源以及部分调度代码
- 每个P维护一个本地G队列
- P需要结合G并绑定到M上才能运行
- P最多有GOMAXPROCS个，并且从程序启动开始就创建好并保持不变
- 当一个P运行的G额外创建一个G时，会进入P的本地G队列中
- 当一个G运行结束后，根据是否需要运行确定是否进入本地队列进行轮转，等待重新运行
- 当P运行的本地队列中没有G，且全局队列中也没有可运行的G时，P会随机选择一个运行中的P的本地G队列偷一半G过来运行（也称抢占式调度）
- 创建的系统线程M多于P的原因是：在M遇到系统中断进入阻塞状态时，会与当前的P解绑，而空闲的M能继续与当前的P绑定并继续提供服务

