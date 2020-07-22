---
title: "Goroutine 运行原理"
date: 2019-03-19T14:45:21+08:00
keywords: ["golang", "goroutine原理"]
categories: ["golang"]
tags: ["golang", "go协程原理", "goroutine原理"]
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


Golang最大的特色可以说是协程(goroutine)了, 协程让本来很复杂的异步编程变得简单, 让程序员不再需要面对回调地狱,
虽然现在引入了协程的语言越来越多, 但go中的协程仍然是实现的是最彻底的.


## 核心概念
要理解协程的实现，需要理解三个重要概念，P、G和M。

G（goroutine）
---
G是goroutine的简写，goroutine可以解释为受管理的轻量级线程，goroutine使用go关键字创建。

main函数是一个主线程，也是一个goroutine。

- goroutine的新建、休眠、回复、停止都受到go运行时的管理
- goroutine执行异步操作时会进入休眠状态，待操作完成后在恢复，无需占用系统线程。
- goroutine新建或恢复时会添加到运行队列，等待M取出并运行。


M（machine）
---
M是machine的简写，表示系统线程

M可以运行两种代码：

- go代码，即goroutine，M运行go代码需要一个P
- 原生代码，例如阻塞的syscall，M运行原生代码不需要P

- M运行时，会从G可运行队列中取出一个然后运行，如果G运行完毕或者进入休眠状态，则从可运行队列中取下一个G运行，周而复始。
- 有时候G需要调用一些无法避免阻塞的原生代码，这时M会释放持有的P并进入阻塞状态。其他M会取得这个P并继续运行队列中的G。

go需要保证有足够的M可以运行G，不让CPU闲着，也需要保证M的数量不过多。


P（process）
---
P是process的简写，代表M运行G所需要的资源。

> 虽然P的数量默认等于cpu的核心数，但可以通过环境变量 **GOMAXPROC** 修改，在实际运行时P跟cpu核心并无任何关联。

P也可以理解为控制go代码的并行度的机制

- 如果P的数量等于1，代表当前最多只能有一个线程M执行go代码。
- 如果P的数量等于2，代表当前最多只能有两个线程M执行go代码。

执行原生代码的线程数不受P控制。


因为同一时间只有一个线程M可以拥有P，P中的数据都是锁自由的，读写这些数据的效率会非常的高。


## 数据结构

G的状态
---

- 空闲中(_Gidle)：表示G刚刚新建，仍未初始化
- 待运行(_Grunnable)：表示G在运行队列中，等待M取出并运行
- 运行中(_Grunning)：表示M正在运行这个G，这时候M会拥有一个P
- 系统调用中(_Gsyscall)：表示M正在运行这个G发起的系统调用，这时候M并不拥有P
- 等待中(_Gwaiting)：表示G在等待某些条件完成，这时候G不在运行也不在运行队列中（可能在channel的等待队列中）
- 已终止(_Gdead)：表示G未被使用，可能已执行完毕（并在freelist中等待下次复用）
- 栈复制中(_Gcopystack)：表示G正在获取一个新的栈空间并把原来的内容复制过去（用于防止GC扫描）

M的状态
---
M并没有像G和P一样的状态标记，但可以认为一个M有以下的状态：

- 自旋中(spinning)：M正在从运行队列获取G，这时候M会拥有一个P
- 执行go代码中：M正在执行go代码，这时候M会拥有一个P
- 执行原生代码中：M正在执行原生代码或者阻塞的syscall，这时M并不拥有P
- 休眠中：M发现没有待运行的G时会进入休眠，并添加到空闲M链表中，这时M并不拥有P


自旋中这个状态非常重要，是否需要唤醒或者创建新的M取决于当前自旋中的M的数量。


P的状态
---
- 空闲中(_Pidle)：当M发现无待运行的G时会进入休眠，这时M拥有的P会变成空闲并加到空闲P链表中
- 运行中(_Prunning)：当M拥有了一个P后，这个P的状态就会变为运行中，M运行G会使用这个P中的资源。
- 系统调用中(_Psyscall)：当go调用原生代码，原生代码又反过来调用go代码时，使用的P会变成此状态
- GC停止中(_Pgcstop)：当gc停止整个世界(STW)时，P会变为此状态。
- 已终止(_Pdead)：当P的数量在运行时改变，且数量减少时多余的P会变为此状态。


本地可运行队列G
---
在go中有多个运行队列可以保存待运行(_Grunnable)的G，他们分别是各个P中的本地运行队列和全局运行队列。

入队待运行的G时会优先加到当前P的本地运行队列，M获取待运行的G时也会优先从拥有的P的本地运行队列获取。

- 本地运行队列有数量限制，当数量达到256个时会入队到全局运行队列
- 本地运行队列的数据结构是环形队列，由一个256长度的数组和两个序号(head,tail)组成


当M从P的本地运行队列获取G时，如果发现本地队列为空会尝试从其他P盗取一半的G过来，这个机制叫做[work stealing](http://supertech.csail.mit.edu/papers/steal.pdf)


全局可运行队列G
---
全局运行队列保存在全局变量sched中，全局运行队列入队和出队需要使用线程锁。

全局运行队列的数据结构是双向链表，由两个指针(head, tail)组成。


空闲M链表
---
当M发现无待运行的G时会进入休眠，并添加到空闲M链表中，空闲M链表保存在全局变量sched。
进入休眠的M会等待一个信号量(m.park)，唤醒休眠的M会使用这个信号量

go需要保证充足的M可以运行G，是通过以下机制实现的：

- 入队运行的G后，如果当前无自旋的M但是有空闲的P，就唤醒或者新建一个M。
- 当M离开自旋状态并准备运行出队的G时，如果当前无自旋的M但是有空闲的P，就唤醒或者新建一个M
- 当M离开自旋状态并准备休眠时，会在离开自旋状态后再次检查所有运行队列，如果有待运行的G则重新进入自旋状态。


因为“入队待运行的G”和“M离开自旋状态”会同时进行，go会使用这样的检查顺序：

- 入队待运行的G
- 内存屏障
- 检查当前自旋的M数量
- 唤醒或新建一个M
- 减少当前自旋的M数量
- 内存屏障
- 检查所有运行队列是否有待运行的G
- 休眠

这样可以保证不会出现待运行的G入队了，也有空闲的资源P，但无M去执行的情况。


空闲P链表
---
当P的本地运行队列中的所有G都运行完毕，又不能从其他地方拿到G时，拥有P的M会释放P并进入休眠状态，释放的P会变成空闲状态并加到空闲P链表中，空闲P链表保存在全局变量sched

下次待运行的G入队时如果发现有空闲的P，但是又没有自旋中的M时会唤醒或者新建一个M，M会拥有这个P，P会重新变为运行中的状态。


工作流程
===
下图是协程可能出现的工作状态，图中有4个P，其中M1~M3正在运行G并且运行后会从拥有的P的运行队列继续获取G。

![/image/golang_goroutine_outline.png](/image/golang_goroutine_outline.png)


只看上面这张图，可能比较难理解工作流程，通过以下代码再了解一遍：
```golang
package main

import (
    "fmt"
    "time"
)

func printNumber(from, to int, c chan int) {
    for x := from; x <= to; x++ {
        fmt.Printf("%d\n", x)
        time.Sleep(1 * time.Millisecond)
    }
    c <- 0
}

func main() {
    c := make(chan int, 3)
    go printNumber(1, 3, c)
    go printNumber(4, 6, c)
    _ = <- c
    _ = <- c
}
```
程序运行结果
```
1
4
2
5
6
3

```
程序启动时会创建一个G，指向的是main（实际是runtime.main而不是main.main）

图中的虚线指的是G待运行或者开始运行的地址，不是当前运行的地址。

![/image/golang_goroutine_main.png](/image/golang_goroutine_main.png)

M会取得这个G并运行：

![/image/golang_goroutine_main_2.png](/image/golang_goroutine_main_2.png)


这时main创建一个新的channel，并启动两个新的G：

![/image/golang_goroutine_main_3.png](/image/golang_goroutine_main_3.png)

接下来G：main 会从channel中获取数据，因为获取不到，G会保存状态并变为等待中(_Gwaiting)并添加到channel的队列

![/image/golang_goroutine_main_4.png](/image/golang_goroutine_main_4.png)

因为G:main保存了运行状态，下次运行时将会从 _=<-c 继续运行

接下来M会从运行队列中获取到G：printNumber并运行：

![/image/golang_goroutine_main_5.png](/image/golang_goroutine_main_5.png)

printNumber会打印数字，完成后向channel写数据

写数据时发现channel中有正在等待的G，会把数据交给这个G，把G变为待运行(_Grunnable)并重新放入运行队列：

![/image/golang_goroutine_main_6.png](/image/golang_goroutine_main_6.png)


接下来M会运行下一个G：printNumber，因为创建channel时指定了大小为3的缓冲区，可以直接把数据写入缓冲区而无需等待：

![/image/golang_goroutine_main_7.png](/image/golang_goroutine_main_7.png)

然后printNumber运行完毕，运行队列中就只剩下了G:main了：

![/image/golang_goroutine_main_8.png](/image/golang_goroutine_main_8.png)

最后M把G：main取出来运行，会从上次中断的位置 _=<-c 继续运行：

![/image/golang_goroutine_main_9.png](/image/golang_goroutine_main_9.png)


第一个_=<-c 的结果已经在前面设置过了，这条语句会执行成功。

第二个_=<-c 在获取时发现channel中已有缓冲的0，于是结果就是这个0，不需要等待。

最后main执行完毕，程序结束。

有人可能会好奇如果最后再加一个 _=<-c会变成什么结果，这时因为所有G都进入等待状态，go会检测出来并报告死锁：
```shell
fatal error: all goroutines are asleep - deadlock!
```

开始代码分析
===

汇编代码
---
上面的程序可生成如下的汇编代码：
```shell
GOOS=linux GOARCH=amd64 go tool compile -S main.go >> main.S
```
```shell
# 有效的配对
    $GOOS		$GOARCH
    android     arm
    darwin      386
    darwin      amd64
    darwin      arm
    darwin      arm64
    dragonfly   amd64
    freebsd     386
    freebsd     amd64
    freebsd     arm
    linux       386
    linux       amd64
    linux       arm
    linux       arm64
    linux       ppc64
    linux       ppc64le
    linux       mips
    linux       mipsle
    linux       mips64
    linux       mips64le
    netbsd      386
    netbsd      amd64
    netbsd      arm
    openbsd     386
    openbsd     amd64
    openbsd     arm
    plan9       386
    plan9       amd64
    solaris     amd64
    windows     386
    windows     amd64

```

```asm
"".printNumber STEXT size=244 args=0x18 locals=0x68
	0x0000 00000 (test_sched.go:8)	TEXT	"".printNumber(SB), $104-24
	0x0000 00000 (test_sched.go:8)	MOVQ	(TLS), CX
	0x0009 00009 (test_sched.go:8)	CMPQ	SP, 16(CX)
	0x000d 00013 (test_sched.go:8)	JLS	234
	0x0013 00019 (test_sched.go:8)	SUBQ	$104, SP
	0x0017 00023 (test_sched.go:8)	MOVQ	BP, 96(SP)
	0x001c 00028 (test_sched.go:8)	LEAQ	96(SP), BP
	0x0021 00033 (test_sched.go:8)	FUNCDATA	$0, gclocals·9ef2fc5b1903b64eb17bd45cd7894e14(SB)
	0x0021 00033 (test_sched.go:8)	FUNCDATA	$1, gclocals·cebf9419b90e46477aa4e5920f8669ae(SB)
	0x0021 00033 (test_sched.go:8)	MOVQ	"".from+112(SP), AX
	0x0026 00038 (test_sched.go:9)	JMP	181
	0x002b 00043 (test_sched.go:9)	MOVQ	AX, "".x+64(SP)
	0x0030 00048 (test_sched.go:10)	MOVQ	AX, ""..autotmp_5+72(SP)
	0x0035 00053 (test_sched.go:10)	XORPS	X0, X0
	0x0038 00056 (test_sched.go:10)	MOVUPS	X0, ""..autotmp_4+80(SP)
	0x003d 00061 (test_sched.go:10)	LEAQ	type.int(SB), CX
	0x0044 00068 (test_sched.go:10)	MOVQ	CX, (SP)
	0x0048 00072 (test_sched.go:10)	LEAQ	""..autotmp_5+72(SP), DX
	0x004d 00077 (test_sched.go:10)	MOVQ	DX, 8(SP)
	0x0052 00082 (test_sched.go:10)	PCDATA	$0, $1
	0x0052 00082 (test_sched.go:10)	CALL	runtime.convT2E64(SB)
	0x0057 00087 (test_sched.go:10)	MOVQ	16(SP), AX
	0x005c 00092 (test_sched.go:10)	MOVQ	24(SP), CX
	0x0061 00097 (test_sched.go:10)	MOVQ	AX, ""..autotmp_4+80(SP)
	0x0066 00102 (test_sched.go:10)	MOVQ	CX, ""..autotmp_4+88(SP)
	0x006b 00107 (test_sched.go:10)	LEAQ	go.string."%d\n"(SB), AX
	0x0072 00114 (test_sched.go:10)	MOVQ	AX, (SP)
	0x0076 00118 (test_sched.go:10)	MOVQ	$3, 8(SP)
	0x007f 00127 (test_sched.go:10)	LEAQ	""..autotmp_4+80(SP), CX
	0x0084 00132 (test_sched.go:10)	MOVQ	CX, 16(SP)
	0x0089 00137 (test_sched.go:10)	MOVQ	$1, 24(SP)
	0x0092 00146 (test_sched.go:10)	MOVQ	$1, 32(SP)
	0x009b 00155 (test_sched.go:10)	PCDATA	$0, $1
	0x009b 00155 (test_sched.go:10)	CALL	fmt.Printf(SB)
	0x00a0 00160 (test_sched.go:11)	MOVQ	$1000000, (SP)
	0x00a8 00168 (test_sched.go:11)	PCDATA	$0, $0
	0x00a8 00168 (test_sched.go:11)	CALL	time.Sleep(SB)
	0x00ad 00173 (test_sched.go:11)	MOVQ	"".x+64(SP), AX
	0x00b2 00178 (test_sched.go:9)	INCQ	AX
	0x00b5 00181 (test_sched.go:9)	MOVQ	"".to+120(SP), CX
	0x00ba 00186 (test_sched.go:9)	CMPQ	AX, CX
	0x00bd 00189 (test_sched.go:9)	JLE	43
	0x00c3 00195 (test_sched.go:9)	MOVQ	"".c+128(SP), AX
	0x00cb 00203 (test_sched.go:13)	MOVQ	AX, (SP)
	0x00cf 00207 (test_sched.go:13)	LEAQ	"".statictmp_0(SB), AX
	0x00d6 00214 (test_sched.go:13)	MOVQ	AX, 8(SP)
	0x00db 00219 (test_sched.go:13)	PCDATA	$0, $2
	0x00db 00219 (test_sched.go:13)	CALL	runtime.chansend1(SB)
	0x00e0 00224 (test_sched.go:14)	MOVQ	96(SP), BP
	0x00e5 00229 (test_sched.go:14)	ADDQ	$104, SP
	0x00e9 00233 (test_sched.go:14)	RET
	0x00ea 00234 (test_sched.go:14)	NOP
	0x00ea 00234 (test_sched.go:8)	PCDATA	$0, $-1
	0x00ea 00234 (test_sched.go:8)	CALL	runtime.morestack_noctxt(SB)
	0x00ef 00239 (test_sched.go:8)	JMP	0
	0x0000 64 48 8b 0c 25 00 00 00 00 48 3b 61 10 0f 86 d7  dH..%....H;a....
	0x0010 00 00 00 48 83 ec 68 48 89 6c 24 60 48 8d 6c 24  ...H..hH.l$`H.l$
	0x0020 60 48 8b 44 24 70 e9 8a 00 00 00 48 89 44 24 40  `H.D$p.....H.D$@
	0x0030 48 89 44 24 48 0f 57 c0 0f 11 44 24 50 48 8d 0d  H.D$H.W...D$PH..
	0x0040 00 00 00 00 48 89 0c 24 48 8d 54 24 48 48 89 54  ....H..$H.T$HH.T
	0x0050 24 08 e8 00 00 00 00 48 8b 44 24 10 48 8b 4c 24  $......H.D$.H.L$
	0x0060 18 48 89 44 24 50 48 89 4c 24 58 48 8d 05 00 00  .H.D$PH.L$XH....
	0x0070 00 00 48 89 04 24 48 c7 44 24 08 03 00 00 00 48  ..H..$H.D$.....H
	0x0080 8d 4c 24 50 48 89 4c 24 10 48 c7 44 24 18 01 00  .L$PH.L$.H.D$...
	0x0090 00 00 48 c7 44 24 20 01 00 00 00 e8 00 00 00 00  ..H.D$ .........
	0x00a0 48 c7 04 24 40 42 0f 00 e8 00 00 00 00 48 8b 44  H..$@B.......H.D
	0x00b0 24 40 48 ff c0 48 8b 4c 24 78 48 39 c8 0f 8e 68  $@H..H.L$xH9...h
	0x00c0 ff ff ff 48 8b 84 24 80 00 00 00 48 89 04 24 48  ...H..$....H..$H
	0x00d0 8d 05 00 00 00 00 48 89 44 24 08 e8 00 00 00 00  ......H.D$......
	0x00e0 48 8b 6c 24 60 48 83 c4 68 c3 e8 00 00 00 00 e9  H.l$`H..h.......
	0x00f0 0c ff ff ff                                      ....
	rel 5+4 t=16 TLS+0
	rel 64+4 t=15 type.int+0
	rel 83+4 t=8 runtime.convT2E64+0
	rel 110+4 t=15 go.string."%d\n"+0
	rel 156+4 t=8 fmt.Printf+0
	rel 169+4 t=8 time.Sleep+0
	rel 210+4 t=15 "".statictmp_0+0
	rel 220+4 t=8 runtime.chansend1+0
	rel 235+4 t=8 runtime.morestack_noctxt+0
"".main STEXT size=286 args=0x0 locals=0x50
	0x0000 00000 (test_sched.go:16)	TEXT	"".main(SB), $80-0
	0x0000 00000 (test_sched.go:16)	MOVQ	(TLS), CX
	0x0009 00009 (test_sched.go:16)	CMPQ	SP, 16(CX)
	0x000d 00013 (test_sched.go:16)	JLS	276
	0x0013 00019 (test_sched.go:16)	SUBQ	$80, SP
	0x0017 00023 (test_sched.go:16)	MOVQ	BP, 72(SP)
	0x001c 00028 (test_sched.go:16)	LEAQ	72(SP), BP
	0x0021 00033 (test_sched.go:16)	FUNCDATA	$0, gclocals·69c1753bd5f81501d95132d08af04464(SB)
	0x0021 00033 (test_sched.go:16)	FUNCDATA	$1, gclocals·9fb7f0986f647f17cb53dda1484e0f7a(SB)
	0x0021 00033 (test_sched.go:17)	LEAQ	type.chan int(SB), AX
	0x0028 00040 (test_sched.go:17)	MOVQ	AX, (SP)
	0x002c 00044 (test_sched.go:17)	MOVQ	$3, 8(SP)
	0x0035 00053 (test_sched.go:17)	PCDATA	$0, $0
	0x0035 00053 (test_sched.go:17)	CALL	runtime.makechan(SB)
	0x003a 00058 (test_sched.go:17)	MOVQ	16(SP), AX
	0x003f 00063 (test_sched.go:17)	MOVQ	AX, "".c+64(SP)
	0x0044 00068 (test_sched.go:18)	MOVQ	$1, 16(SP)
	0x004d 00077 (test_sched.go:18)	MOVQ	$3, 24(SP)
	0x0056 00086 (test_sched.go:18)	MOVQ	AX, 32(SP)
	0x005b 00091 (test_sched.go:18)	MOVL	$24, (SP)
	0x0062 00098 (test_sched.go:18)	LEAQ	"".printNumber·f(SB), CX
	0x0069 00105 (test_sched.go:18)	MOVQ	CX, 8(SP)
	0x006e 00110 (test_sched.go:18)	PCDATA	$0, $1
	0x006e 00110 (test_sched.go:18)	CALL	runtime.newproc(SB)
	0x0073 00115 (test_sched.go:19)	MOVQ	$4, 16(SP)
	0x007c 00124 (test_sched.go:19)	MOVQ	$6, 24(SP)
	0x0085 00133 (test_sched.go:19)	MOVQ	"".c+64(SP), AX
	0x008a 00138 (test_sched.go:19)	MOVQ	AX, 32(SP)
	0x008f 00143 (test_sched.go:19)	MOVL	$24, (SP)
	0x0096 00150 (test_sched.go:19)	LEAQ	"".printNumber·f(SB), CX
	0x009d 00157 (test_sched.go:19)	MOVQ	CX, 8(SP)
	0x00a2 00162 (test_sched.go:19)	PCDATA	$0, $1
	0x00a2 00162 (test_sched.go:19)	CALL	runtime.newproc(SB)
	0x00a7 00167 (test_sched.go:21)	MOVQ	$0, ""..autotmp_1+56(SP)
	0x00b0 00176 (test_sched.go:21)	MOVQ	"".c+64(SP), AX
	0x00b5 00181 (test_sched.go:21)	MOVQ	AX, (SP)
	0x00b9 00185 (test_sched.go:21)	LEAQ	""..autotmp_1+56(SP), CX
	0x00be 00190 (test_sched.go:21)	MOVQ	CX, 8(SP)
	0x00c3 00195 (test_sched.go:21)	PCDATA	$0, $1
	0x00c3 00195 (test_sched.go:21)	CALL	runtime.chanrecv1(SB)
	0x00c8 00200 (test_sched.go:22)	MOVQ	$0, ""..autotmp_2+48(SP)
	0x00d1 00209 (test_sched.go:22)	MOVQ	"".c+64(SP), AX
	0x00d6 00214 (test_sched.go:22)	MOVQ	AX, (SP)
	0x00da 00218 (test_sched.go:22)	LEAQ	""..autotmp_2+48(SP), CX
	0x00df 00223 (test_sched.go:22)	MOVQ	CX, 8(SP)
	0x00e4 00228 (test_sched.go:22)	PCDATA	$0, $1
	0x00e4 00228 (test_sched.go:22)	CALL	runtime.chanrecv1(SB)
	0x00e9 00233 (test_sched.go:23)	MOVQ	$0, ""..autotmp_3+40(SP)
	0x00f2 00242 (test_sched.go:23)	MOVQ	"".c+64(SP), AX
	0x00f7 00247 (test_sched.go:23)	MOVQ	AX, (SP)
	0x00fb 00251 (test_sched.go:23)	LEAQ	""..autotmp_3+40(SP), AX
	0x0100 00256 (test_sched.go:23)	MOVQ	AX, 8(SP)
	0x0105 00261 (test_sched.go:23)	PCDATA	$0, $0
	0x0105 00261 (test_sched.go:23)	CALL	runtime.chanrecv1(SB)
	0x010a 00266 (test_sched.go:24)	MOVQ	72(SP), BP
	0x010f 00271 (test_sched.go:24)	ADDQ	$80, SP
	0x0113 00275 (test_sched.go:24)	RET
	0x0114 00276 (test_sched.go:24)	NOP
	0x0114 00276 (test_sched.go:16)	PCDATA	$0, $-1
	0x0114 00276 (test_sched.go:16)	CALL	runtime.morestack_noctxt(SB)
	0x0119 00281 (test_sched.go:16)	JMP	0
```

调用规范
---
go有一套独自的调用规范

o的调用规范非常的简单, 所有参数都通过栈传递, 返回值也通过栈传递,

例如这样的函数：
```golang
type MyStruct struct { X int; P *int }
func someFunc(x int, s MyStruct) (int, MyStruct) { ... }
```
其运行时调用栈如下：

![/image/golang_goroutine_stack.png](/image/golang_goroutine_stack.png)

可以看得出参数和返回值都从低位到高位排列, go函数可以有多个返回值的原因也在于此. 因为返回值都通过栈传递了.
需要注意的这里的"返回地址"是x86和x64上的, arm的返回地址会通过LR寄存器保存, 内容会和这里的稍微不一样.
另外注意的是和c不一样, 传递构造体时整个构造体的内容都会复制到栈上, 如果构造体很大将会影响性能.


TLS
---

TLS的全称是Thread-local storage, 代表每个线程的中的本地数据.

例如标准c中的errno就是一个典型的TLS变量, 每个线程都有一个独自的errno, 写入它不会干扰到其他线程中的值.
go在实现协程时非常依赖TLS机制, 会用于获取系统线程中当前的G和G所属的M的实例


因为go并不使用glibc, 操作TLS会使用系统原生的接口, 以linux x64为例,
go在新建M时会调用arch_prctl这个syscall设置FS寄存器的值为M.tls的地址,
运行中每个M的FS寄存器都会指向它们对应的M实例的tls, linux内核调度线程时FS寄存器会跟着线程一起切换,
这样go代码只需要访问FS寄存器就可以存取线程本地的数据.


栈扩张
---
因为go中的协程是stackful coroutine, 每一个goroutine都需要有自己的栈空间,
栈空间的内容在goroutine休眠时需要保留, 待休眠完成后恢复(这时整个调用树都是完整的).
这样就引出了一个问题, goroutine可能会同时存在很多个, 如果每一个goroutine都预先分配一个足够的栈空间那么go就会使用过多的内存.

为了避免这个问题, go在一开始只为goroutine分配一个很小的栈空间, 它的大小在当前版本是2K.
当函数发现栈空间不足时, 会申请一块新的栈空间并把原来的栈内容复制过去.


写屏障(write barrier)
---
因为go支持并行GC, GC的扫描和go代码可以同时运行, 这样带来的问题是GC扫描的过程中go代码有可能改变了对象的依赖树,
例如开始扫描时发现根对象A和B, B拥有C的指针, GC先扫描A, 然后B把C的指针交给A, GC再扫描B, 这时C就不会被扫描到.
为了避免这个问题, go在GC的标记阶段会启用写屏障(Write Barrier).

启用了写屏障(Write Barrier)后, 当B把C的指针交给A时, GC会认为在这一轮的扫描中C的指针是存活的,
即使A可能会在稍后丢掉C, 那么C就在下一轮回收.
写屏障只针对指针启用, 而且只在GC的标记阶段启用, 平时会直接把值写入到目标地址:

关于写屏障的详细将在下一篇(GC篇)分析.
值得一提的是CoreCLR的GC也有写屏障的机制, 但作用跟这里的不一样(用于标记跨代引用).


闭包(Closure)
---
golang闭包的实现
```golang
package main

import (
    "fmt"
)

func executeFn(fn func() int) int {
    return fn();
}

func main() {
    a := 1
    b := 2
    c := executeFn(func() int {
        a += b
        return a
    })
    fmt.Printf("%d %d %d\n", a, b, c)
}
```
调用闭包时参数并不通过栈传递, 而是通过寄存器rdx传递,


闭包的传递可以总结如下：

- 闭包的内容是[匿名函数的地址，传给匿名函数的参数（不定长）...]
- 传递闭包给其他函数时会传递指向闭包内容的指针
- 闭包会从寄存器rdx取出参数
- 如果闭包修改了变量，闭包中的参数会是指针而不是值，修改时会修改到原来的位置上。

闭包+goroutine
---
细心的可能会发现在上面的例子中, 闭包的内容在栈上, 如果不是直接调用executeFn而是go executeFn呢?


 首先go会通过逃逸分析算出变量a和闭包会逃逸到外面,
这时go会在heap上分配变量a和闭包, 上面调用的两次newobject就是分别对变量a和闭包的分配.

m0和g0
---
go中还有特殊的M和G, 它们是m0和g0.

m0是启动程序后的主线程, 这个m对应的实例会在全局变量m0中, 不需要在heap上分配,
m0负责执行初始化操作和启动第一个g, 在之后m0就和其他的m一样了.

g0是仅用于负责调度的G, g0不指向任何可执行的函数, 每个m都会有一个自己的g0,
在调度或系统调用时会使用g0的栈空间, 全局变量的g0是m0的g0.



程序初始化
===

go程序的入口点是[runtime.rt0_g0](https://github.com/golang/go/blob/go1.9.2/src/runtime/asm_amd64.s)，流程如下：

- 分配栈空间，需要2个本地变量+2个函数参数，然后向8对齐
- 把传入的argc和argv保存到栈上
- 更新g0中的stackguard的值，stackguard用于检测栈空间是否不足，需要分配新的栈空间
- 获取当前cpu的信息并保存到各个全局变量中
- 调用_cgo_init如果函数存在
- 初始化当前线程的TLS，设置FS寄存器为m0.tls+8（获取时会-8）
- 测试TLS是否工作
- 设置g0到TLS中，表示当前的g是g0
- 设置m0.g0 = g0
- 设置g0.m = m0
- 调用[runtime.check](https://github.com/golang/go/blob/go1.9.2/src/runtime/runtime1.go#L140)做一些检查
- 调用[runtime.args](https://github.com/golang/go/blob/go1.9.2/src/runtime/runtime1.go#L60) 保存传入的argc和argv全局变量
- 调用[runtime.osinit](https://github.com/golang/go/blob/go1.9.2/src/runtime/os_linux.go#L269)根据系统执行不同的初始化
    - 这里(linux amd64)设置了全局变量ncpu等于cpu核心数
- 调用[runtime.schedinit](https://github.com/golang/go/blob/go1.9.2/src/runtime/proc.go#L468)执行共同的初始化
    - 这里的处理比较多，会初始化栈空间分配器，GC,按cpu核心数或GOMAXPROCS的值生成P等
    - 生成P的处理在[procresize](https://github.com/golang/go/blob/go1.9.2/src/runtime/proc.go#L3517)中
- 调用[runtime.newproc](https://github.com/golang/go/blob/go1.9.2/src/runtime/proc.go#L2929)创建一个新的goroutine，指向的是runtime.main
    - runtime.newproc这个函数在创建普通的goroutine时也会使用
- 调用[runtime.mstart](https://github.com/golang/go/blob/go1.9.2/src/runtime/proc.go#L1135)启动m0
    - 启动后m0会不断从运行队列获取G并运行，runtime.mstart调用后不会返回
    - runtime.mstart这个函数是m的入口点


第一个被调度的G会运行runtime.main，流程是：

- 标记主函数已调用，设置mainStarted = true
- 启动一个新的M执行sysmon函数，这个函数会监控全局的状态并对运行时间过长的G进行抢占
- 要求G必须在当前M上执行
- 调用[runtime_init](https://github.com/golang/go/blob/go1.9.2/src/runtime/proc.go#L233)函数
- 调用[gcenable](https://github.com/golang/go/blob/go1.9.2/src/runtime/mgc.go#L214)函数
- 调用main.init函数，如果函数存在
- 不在要求G必须在当前M上运行
- 如果程序是作为c的类库编译，在这里返回
- 调用main.main函数
- 如果当前发生了panic，则等待panic处理
- 带哦用exit(0)退出程序


G M P的定义
---
G的定义[在这里](https://github.com/golang/go/blob/go1.9.2/src/runtime/runtime2.go#L320).
M的定义[在这里](https://github.com/golang/go/blob/go1.9.2/src/runtime/runtime2.go#L383).
P的定义[在这里)(https://github.com/golang/go/blob/go1.9.2/src/runtime/runtime2.go#L450).

#### G里面比较重要的成员如下

- stack: 当前g使用的栈空间, 有lo和hi两个成员
- stackguard0: 检查栈空间是否足够的值, 低于这个值会扩张栈, 0是go代码使用的
- stackguard1: 检查栈空间是否足够的值, 低于这个值会扩张栈, 1是原生代码使用的
- m: 当前g对应的m
- sched: g的调度数据, 当g中断时会保存当前的pc和rsp等值到这里, 恢复运行时会使用这里的值
- atomicstatus: g的当前状态
- schedlink: 下一个g, 当g在链表结构中会使用
- preempt: g是否被抢占中
- lockedm: g是否要求要回到这个M执行, 有的时候g中断了恢复会要求使用原来的M执行

#### M里面比较重要的成员如下
- g0: 用于调度的特殊g, 调度和执行系统调用时会切换到这个g
- curg: 当前运行的g
- p: 当前拥有的P
- nextp: 唤醒M时, M会拥有这个P
- park: M休眠时使用的信号量, 唤醒M时会通过它唤醒
- schedlink: 下一个m, 当m在链表结构中会使用
- mcache: 分配内存时使用的本地分配器, 和p.mcache一样(拥有P时会复制过来)
- lockedg: lockedm的对应值

#### P里面比较重要的成员如下

- status: p的当前状态
- link: 下一个p, 当p在链表结构中会使用
- m: 拥有这个P的M
- mcache: 分配内存时使用的本地分配器
- runqhead: 本地运行队列的出队序号
- runqtail: 本地运行队列的入队序号
-  runq: 本地运行队列的数组, 可以保存256个G
- gfree: G的自由列表, 保存变为_Gdead后可以复用的G实例
- gcBgMarkWorker: 后台GC的worker函数, 如果它存在M会优先执行它
- gcw: GC的本地工作队列


go的实现
---


调度器的实现
---


抢占的实现
---


channel的实现
---


参考文献：

- [http://www.cnblogs.com/zkweb/p/7815600.html?utm_campaign=studygolang.com&utm_medium=studygolang.com&utm_source=studygolang.com](http://www.cnblogs.com/zkweb/p/7815600.html?utm_campaign=studygolang.com&utm_medium=studygolang.com&utm_source=studygolang.com)




