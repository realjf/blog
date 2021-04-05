---
title: "Golang调度模型 Golang Scheduling Model"
date: 2021-04-05T22:15:42+08:00
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

go实现的是M个用户线程（协程）运行在N个内核线程上的模型，其能充分利用cpu资源的同时，保持高度处理效率。

golang的调度模型可以用processor(简称P)、machine(简称M)、goroutine(简称G)来描述。

- P (processor)：golang调度模型里的处理器P，包含运行goroutine协程所必须的资源以及相应的调度功能
- G (groutine)：即go协程，通过go关键字创建
- M (machine)：系统线程或内核线程，由操作系统调度

其中，M必须与P结合才能执行代码（可以理解为运行go协程代码段），同时M也受系统调度影响。
而每个P带有一个go协程待运行队列，同时调度器还保持一个全局go协程待调度队列，供全部处理器共享。



