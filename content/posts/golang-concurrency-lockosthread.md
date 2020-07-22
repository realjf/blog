---
title: "Golang 并发编程 之 runtime.LockOSThread"
date: 2019-11-21T17:10:37+08:00
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

背景介绍
---
一些库（尤其是图形框架和库（例如Cocoa，OpenGL和libSDL））使用线程局部状态，并且可能要求仅从特定OS线程（通常是“主”线程）调用函数。
Go为此提供了runtime.LockOSThread函数，接下来通过示例说明如何正确使用它。

```go
package dl

import (
	"fmt"
	"runtime"
)

// 安排main.main在主线程上运行
func init() {
	runtime.LockOSThread()
}

// 在主线程main.main中调用Main循环
func Main() {
	for f := range mainfunc {
		// 取出工作队列中的函数进行调用
		f()
	}
}

var mainfunc = make(chan func())

func do(f func()) {
	done := make(chan bool, 1)
	// 将整个函数加入到工作队列中
	mainfunc <- func() {
		f()
		fmt.Println("add queue")
		done <- true
	}
	<-done
}

func Beep() {
	do(func() {
		// 无论什么时候都运行在主线程
		fmt.Println("beep")
	})
}

```
main包示例：
```go
func main(){
	go func() {
		for {
			dl.Beep()
		}
	}()

	dl.Main()
}
```


