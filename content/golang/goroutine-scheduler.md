---
title: "Goroutine Scheduler 机制分析"
date: 2020-01-20T11:20:27+08:00
keywords: ["golang", "goroutine scheduler"]
categories: ["golang"]
tags: ["golang", "goroutine scheduler"]
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

Goroutine scheduler，即调度程序的任务是在工作线程上分发准备好运行的goroutines
> goroutine scheduler 机制主要在/runtime/proc.go文件中实现

## goroutine scheduler 机制分析
主要的概念包括：
- G goroutine
- M 工作线程，或者系统线程
- P 处理器，执行go代码所需的系统资源，M必须有一个关联的P来执行Go代码，但是它可以是阻塞的或在系统调用中没有关联的P。










