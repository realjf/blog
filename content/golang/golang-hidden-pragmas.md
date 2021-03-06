---
title: "Golang 隐藏编译指令 Golang Hidden Pragmas"
date: 2021-05-05T08:34:47+08:00
keywords: ["golang", "golang pragmas", "go编译指令"]
categories: ["golang"]
tags: ["golang", "golang pragmas", "go编译指令"]
series: ["golang"]
draft: false
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
如上，这是一个go语言的编译指令，意思是让编译器不进行内存逃逸分析

```go
//go:norace
```
使编译器不会报告数据竞争，即跳过竞争检测


```go
//go:nosplit
```
当用Go重写运行时时，仍然需要一种说不应该对特定函数进行堆栈拆分检查的方式，
这通常是需要的，因为禁止在运行时内部进行堆栈拆分，因为堆栈拆分隐式需要分配内存，这将导致递归行为。
使用//go:nosplit表示“我现在不想增加堆栈”，编译器仍然必须确保可以安全地运行该函数。
Go是一种内存安全的语言，我们不能仅仅因为它们想要避免栈检查的开销而让函数使用超出其允许范围的栈。
他们几乎肯定会破坏堆或其他goroutine的内存。

```go
//go:noinline
```
禁止内联

内联通过将内联函数的代码复制到其调用方中，从而改善了堆栈检查前同步码的成本以及实际上所有函数调用的开销。
通过避免函数调用开销，可以在增加程序大小和减少运行时间之间进行很小的折衷。
内联是编译器优化的关键，因为它可以解锁许多其他优化。


```go
//go:nowritebarrier
```
意思很明显，让编译器禁用内存写屏障


```go
import _ "unsafe"

//go:linkname localname github.com/xxx/xxx/xxx.xxx
```
引导编译器将当前(私有)方法或者变量在编译时链接到指定的位置的方法或者变量，第一个参数表示当前方法或变量，第二个参数表示目标方法或变量，因为这关指令会破坏系统和包的模块化，因此在使用时必须导入unsafe，
如：

time/time.go
```go
...
func now() (sec int64, nsec int32, mono int64)
```
runtime/timestub.go文件里的代码
```go
import _ "unsafe" // for go:linkname

//go:linkname time_now time.now
func time_now() (sec int64, nsec int32, mono int64) {
	sec, nsec = walltime()
	return sec, nsec, nanotime() - startNano
}
```
可以看到 time.now，它并没有具体的实现。如果你初看可能会懵逼。这时候建议你全局搜索一下源码，你就会发现其实现在 runtime.time_now 中
配合先前的用法解释，可得知在 runtime 包中，我们声明了 time_now 方法是 time.now 的符号别名。并且在文件头引入了 unsafe 达成前提条件



