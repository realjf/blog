---
title: "golang Slice类型扩容机制"
date: 2020-04-28T15:10:49+08:00
keywords: ["golang"]
categories: ["golang"]
tags: ["golang"]
series: [""]
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

一个slice是一个数组某个部分的引用。在内存中，他是一个包含3个域的结构体：指向slice中第一个元素的指针，slice的长度，以及slice的容量。长度是下标操作的上界，容量是分割操作的上界


数组的slice并不会实际复制一份数据，他只是创建一个新的数据结构，包含了另外的一个指针，一个长度和一个容量数据。如同分割字符串，分割数组也不涉及复制操作：它只是新建了一个结构来放置一个不同的指针，长度和容量。


由于slice是不同于指针的多字长结构，分割操作并不需要分配内存，甚至没有通常被保存在堆中的slice头部，这种表示方法使slice操作和在c中传递指针、长度对一样廉价。移除间接引用及分配操作可以让slice足够廉价，以避免传递显式索引。


#### slice的扩容
在对slice进行append等操作时，可能会造成slice的自动扩容。其扩容时的大小增长规则是：
- 如果新的大小是当前大小2倍以上，则大小增长为新大小
- 否则循环以下操作：如果当前大小小于1024，按每次2倍增长，否则每次按当前大小1/4增长。直到增长的大小超过或等于新大小。



#### make和new
有两个数据结构创建函数：new和make，基本区别是new（T）返回一个*T，返回的这个指针可以被隐式地消除索引，而make(T, args)返回一个 普通的T，通常情况下，T内部有一些隐式的指针，一句话，new返回一个指向已清零内存的指针，而make返回一个复杂的结构。


#### slice与unsafe.Pointer相互转换
有时候可能需要使用一些比较tricky的技巧，比如利用make弄一块内存自己管理，或者用cgo之类的方式得到的内存，转换为Go类型使用。
从slice中得到一块内存地址是很容易的：
```golang

s := make([]byte, 200)
ptr := unsafe.Pointer(&s[0])

```
从一个内存指针构造出go语言的slice结构相对麻烦些，比如：
```golang
var ptr unsafe.Pointer
s := ((*[1<<10]byte)(ptr))[:200]
```
先将ptr强制类型转换为另外一种指针，一个指向[1<<10]byte数组的指针，这里数组大小其实是假的，然后用slice操作取出这个数组的前200个，于是s就是一个200个元素的slice

或者：
```golang
var ptr unsafe.Pointer
var s1 = struct {
    addr uintptr
    len int
    cap int
}{ptr, length, length}
s := *(*[]byte)(unsafe.Pointer(&s1))

```

或者使用reflect.SliceHeader的方式构造slice，比较推荐这种：
```golang
var o []byte
sliceHeader := (*reflect.SliceHeader)((unsafe.Pointer(&o)))
sliceHeader.Cap = length
sliceHeader.Len = length
sliceHeader.Data = uintptr(ptr)

```




