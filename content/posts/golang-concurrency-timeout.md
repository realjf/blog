---
title: "Golang 并发编程 之 超时处理"
date: 2019-11-21T17:10:13+08:00
keywords: ["golang", "concurrency", "timeout"]
categories: ["golang"]
tags: ["golang", "concurrency", "timeout"]
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

并发编程中的超时处理
===
在并发编程中，要放弃运行时间太长的同步调用，请使用带有time.After的select语句，如下：
```go
import (
	"errors"
	"fmt"
	"time"
)

func main() {
	var timeoutNanoseconds time.Duration = 5 * time.Second
	c := make(chan error, 1)
	go func() {
		time.Sleep(20 * time.Second)
		c <- errors.New("error")
	} ()
	select {
	case err := <-c:
		// use err and reply
		fmt.Println(err)
	case <-time.After(timeoutNanoseconds):
		// call timed out
		fmt.Println("timeout...")
	}
}
```
以上代码在超时5秒后退出


