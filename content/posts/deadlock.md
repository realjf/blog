---
title: "死锁 Deadlock"
date: 2020-04-16T15:28:20+08:00
keywords: ["deadlock", "死锁"]
categories: ["posts"]
tags: ["deadlock"]
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

### 什么是死锁？
简单说，是指两个或两个以上的线程在执行过程中，彼此持有对方需要的资源和处于等待对方释放资源的现象，
如果没有外力作用，这种状态将一直持续下去。

### 如何避免？
避免死锁的一般建议是：对竞争资源按顺序采用互斥加锁

当然，如果能在编程时就注意这方便的问题，将可以用更好的方式，比如：

- 避免嵌套锁
- 避免在持有锁时调用用户提供的代码
- 使用固定顺序获取锁
- 使用锁的层次结构
