---
title: "Channel 底层实现"
date: 2020-01-20T09:08:15+08:00
keywords: ["golang", "channel"]
categories: ["golang"]
tags: ["channel", "golang"]
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

channel是golang的一大特色，golang的goroutine之间的通信也建议通过channel机制实现。
那么我们有必要探讨下，channel的底层实现机制，以便我们更好的应用channel。

> 本次探讨版本为go v1.13
## channel的实现原理
go中实现channel的文件包含在/runtime/chan.go中
```go
type hchan struct {
	qcount   uint           // total data in the queue
	dataqsiz uint           // size of the circular queue
	buf      unsafe.Pointer // points to an array of dataqsiz elements
	elemsize uint16
	closed   uint32
	elemtype *_type // element type
	sendx    uint   // send index
	recvx    uint   // receive index
	recvq    waitq  // list of recv waiters
	sendq    waitq  // list of send waiters

	// lock protects all fields in hchan, as well as several
	// fields in sudogs blocked on this channel.
	//
	// Do not change another G's status while holding this lock
	// (in particular, do not ready a G), as this can deadlock
	// with stack shrinking.
	lock mutex
}
```
可以看到，chan包含的结构如下域：
- qcount 队列总数据
- dataqsiz 循环队列的大小
- buf 有缓冲的channel所特有的结构，用来存储缓存数据。是个循环链表
- sendx和recvx 用于记录buf这个循环链表中的~发送或者接收的~index
- sendq和recvq 分别是接收(<-channel)或者发送(channel <- xxx)的goroutine抽象出来的结构体(sudog)的队列。是个双向链表
- lock 一个互斥锁，保护所有域

### 开始分析
从如下例子开始
```go
ch1 := make(chan int, 5)
```
创建一个缓存大小为1的int型的channel,并返回一个指针。
其中的5表示的就是循环队列的大小

> 具体的实现可以查看makechan函数

接下来我们看下channel的内部机制实现

#### channel的先进先出队列
channel队列实现需要用到buf、sendx、recvx以及lock。

当发送和接收数据时，需要使用互斥锁lock住整个结构体，以避免被其他操作修改。

锁住之后就可以开始发送数据了，发送使用 ch1<- xxx 进行发送。具体的代码如下
```go
func chansend(c *hchan, ep unsafe.Pointer, block bool, callerpc uintptr) bool {
	
	...

	lock(&c.lock)

	if c.closed != 0 {
		unlock(&c.lock)
		panic(plainError("send on closed channel"))
	}

	if sg := c.recvq.dequeue(); sg != nil {
		// Found a waiting receiver. We pass the value we want to send
		// directly to the receiver, bypassing the channel buffer (if any).
		send(c, sg, ep, func() { unlock(&c.lock) }, 3)
		return true
	}

	if c.qcount < c.dataqsiz {
		// Space is available in the channel buffer. Enqueue the element to send.
		qp := chanbuf(c, c.sendx)
		if raceenabled {
			raceacquire(qp)
			racerelease(qp)
		}
		typedmemmove(c.elemtype, qp, ep)
		c.sendx++
		if c.sendx == c.dataqsiz {
			c.sendx = 0
		}
		c.qcount++
		unlock(&c.lock)
		return true
	}

	if !block {
		unlock(&c.lock)
		return false
	}

	...
}
```
由上述代码可以看到，如果队列空闲，则直接元素直接入队，即把数据复制到缓存队列中。
发送成功后，sendx会自增1，而qcount页自增1，然后解除互斥锁。

在缓存队列满了之后，将处于阻塞状态，等待接收操作以空出冗余空间。

接下来是接收操作，使用<-ch进行接收，代码如下：
```go
func chanrecv(c *hchan, ep unsafe.Pointer, block bool) (selected, received bool) {
	...
	
	lock(&c.lock)

	if c.closed != 0 && c.qcount == 0 {
		if raceenabled {
			raceacquire(c.raceaddr())
		}
		unlock(&c.lock)
		if ep != nil {
			typedmemclr(c.elemtype, ep)
		}
		return true, false
	}

	if sg := c.sendq.dequeue(); sg != nil {
		// Found a waiting sender. If buffer is size 0, receive value
		// directly from sender. Otherwise, receive from head of queue
		// and add sender's value to the tail of the queue (both map to
		// the same buffer slot because the queue is full).
		recv(c, sg, ep, func() { unlock(&c.lock) }, 3)
		return true, true
	}

	if c.qcount > 0 {
		// Receive directly from queue
		qp := chanbuf(c, c.recvx)
		if raceenabled {
			raceacquire(qp)
			racerelease(qp)
		}
		if ep != nil {
			typedmemmove(c.elemtype, ep, qp)
		}
		typedmemclr(c.elemtype, qp)
		c.recvx++
		if c.recvx == c.dataqsiz {
			c.recvx = 0
		}
		c.qcount--
		unlock(&c.lock)
		return true, true
	}

	...
}
```
由上述代码可以看出，接收数据时也是先加锁，然后从缓存队列中复制数据到对应的goroutine中。
接收成功后，recvx自增1，qcount自减1，最后解锁。


**由以上发送接收数据可以看出，两个goroutine之间通过channel通信，实质上是把数据从一端赋值到另一端。**



**参考文献**：
- [https://studygolang.com/articles/20714](https://studygolang.com/articles/20714)








