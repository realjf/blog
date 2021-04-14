---
title: "Golang 隐藏编译指令"
date: 2019-11-25T00:34:47+08:00
keywords: ["golang", "golang pragmas", "go编译指令"]
categories: ["golang"]
tags: ["golang", "golang pragmas", "go编译指令"]
series: ["golang"]
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

说到编译指令，许多语言支持，如rust,c,javascript等，这里必须要提及下c语言的编译指令#pragma，它的作用是设定编译器的状态或者是指示编译器完成一些特定的动作,
如：
- #pragma once 用于保证头文件只被编译一次，
- #pragma message 用于自定义编译信息
- #pragama pack用于指定内存对齐

那么go语言是否有相应的编译指令呢？答案是肯定的。

## go语言的编译指令
c语言使用#pragma编写预处理编译指令，但是go没有这种预处理器或宏，
那go使用什么来制定编译指令呢？

我们先来看个例子：
```go
//go:noescape
func printf(*s stirng) (err error){
...
}
```
如上，这是一个go语言的编译指令，意思是不进行内存逃逸分析



