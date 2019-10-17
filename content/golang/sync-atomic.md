---
title: "Golang语言标准库之 sync/atomic原子操作"
date: 2019-10-17T17:37:02+08:00
draft: false
---

原子操作，顾名思义是不可分割的，他可以是一个步骤，也可以是多个步骤，其执行过程不会被线程调度机制打断的操作。

> 原子性不可能由软件单独保证，需要硬件的支持，因此和架构有关。在x86架构平台下，cpu提供了在指令执行期间对总线加锁的手段。\
CPU芯片上有一条引线#HLOCK pin，如果汇编语言的程序中在一条指令前面加上前缀"LOCK"，经过汇编以后的机器代码就使CPU在执行这条指令的时候把#HLOCK pin的电位拉低，\
持续到这条指令结束时放开，从而把总线锁住，这样同一总线上别的CPU就暂时不能通过总线访问内存了，保证了这条指令在多处理器环境中的原子性。

sync/atomic包的文件结构以及数据结构可以参考[这里](https://coggle.it/diagram/Xag3knoA8i_zpoat/t/-/b45bf815722b49b694e05c677e46afd16aad61d414815df8ec24b15bed61b62a)

sync/atomic包提供了6中操作数据类型
- int32
- uint32
- int64
- uint64
- uintptr
- unsafe.Pointer

分别为这每种数据类型提供了五种操作
- add 增减
- load 载入
- store 存储
- compareandswap 比较并交换
- swap 交换


### 下面以int32为例，具体使用上面五种操作实现原子操作
#### AddInt32操作
```go
var val int32
val = 10
atomic.AddInt32(&val, 10)

// 对于无符号32位即uint32，则需要使用二进制补码进行操作
var val2 uint32
val2 = 10
atomic.AddUint32(&val2, ^uint32(10 - 1)) // 等价于 val2 - 10

```
#### CompareAndSwapInt32
对比并交换是指先判断addr指向的值是否与参数old一致，如果一致就用new值替换addr的值，最后返回成功，具体例子如下
```go
package main
import (
	"fmt"
	"sync"
	"sync/atomic"
)
func main() {
	var val int32
	wg := sync.WaitGroup{}
	//开启100个goroutine
	for i := 0; i < 100; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			old := atomic.LoadInt32(&val)
			if !atomic.CompareAndSwapInt32(&val, old, old+1) {
				fmt.Println("修改失败")
			}
		}()
	}
	wg.Wait()
	//val的值有可能不等于100，频繁修改变量值情况下，CompareAndSwap操作有可能不成功。
	fmt.Println("c : ", val)
}
```
#### SwapInt32
进行赋值操作，然后返回旧值
```go
var val int32
buf := atomic.LoadInt32(&val)
old := atomic.SwapInt32(&val, buf + 1)

```

#### LoadInt32
载入一个int32的值，只保证读取的时候是原子的，即不是正在写入的值

#### StoreInt32
向存储地址写入指定值，保证存储的时候不会被读写操作，即保证写入的原子性
