---
title: "Golang GC 实现原理"
date: 2019-03-19T14:49:57+08:00
draft: true
---


当前的1.9版本的GC停顿时间已经可以做到极短.
停顿时间的减少意味着"最大响应时间"的缩短, 这也让go更适合编写网络服务程序.
这篇文章将通过分析golang的源代码来讲解go中的三色GC的实现原理.


## 基础概念

#### 内存结构
go在程序启动时会分配一块虚拟内存地址是连续的内存，结构如下：

![https://images2017.cnblogs.com/blog/881857/201711/881857-20171122165637665-171579804.png](https://images2017.cnblogs.com/blog/881857/201711/881857-20171122165637665-171579804.png)

这一块内存分为了3个区域, 在X64上大小分别是512M, 16G和512G, 它们的作用如下:

##### arena

arena区域就是我们通常说的heap, go从heap分配的内存都在这个区域中.

##### bitmap

bitmap区域用于表示arena区域中哪些地址保存了对象, 并且对象中哪些地址包含了指针.
bitmap区域中一个byte(8 bit)对应了arena区域中的四个指针大小的内存, 也就是2 bit对应一个指针大小的内存.
所以bitmap区域的大小是 512GB / 指针大小(8 byte) / 4 = 16GB.


bitmap区域中的一个byte对应arena区域的四个指针大小的内存的结构如下,
每一个指针大小的内存都会有两个bit分别表示是否应该继续扫描和是否包含指针:

![https://images2017.cnblogs.com/blog/881857/201711/881857-20171122165646055-1225522876.png](https://images2017.cnblogs.com/blog/881857/201711/881857-20171122165646055-1225522876.png)

bitmap中的byte和arena的对应关系从末尾开始, 也就是随着内存分配会向两边扩展:

![https://images2017.cnblogs.com/blog/881857/201711/881857-20171122165652071-1143420937.png](https://images2017.cnblogs.com/blog/881857/201711/881857-20171122165652071-1143420937.png)


##### spans
spans区域用于表示arena区中的某一页(Page)属于哪个span, 什么是span将在下面介绍.
spans区域中一个指针(8 byte)对应了arena区域中的一页(在go中一页=8KB).
所以spans的大小是 512GB / 页大小(8KB) * 指针大小(8 byte) = 512MB.

spans区域的一个指针对应arena区域的一页的结构如下, 和bitmap不一样的是对应关系会从开头开始:

![https://images2017.cnblogs.com/blog/881857/201711/881857-20171122165701665-214853306.png](https://images2017.cnblogs.com/blog/881857/201711/881857-20171122165701665-214853306.png)


#### 什么时候从heap分配对象
go对自动确定哪些对象应该放在栈上，哪些对象应该放在堆上。
简单说，当一个对象的内容可能在生成该对象的函数结束后被访问，那么这个对象就会分配到堆上


在堆上分配的对象的情况包括：
- 返回对象的指针
- 传递了对象的指针到其他函数
- 在闭包中是用来对象并且需要修改对象
- 使用new

在C语言中函数返回在栈上的对象的指针是非常危险的事情, 但在go中却是安全的, 因为这个对象会自动在堆上分配.
go决定是否使用堆分配对象的过程也叫"逃逸分析".

#### GC Bitmap
GC在标记时需要知道哪些地方包含了指针, 例如上面提到的bitmap区域涵盖了arena区域中的指针信息.
除此之外, GC还需要知道栈空间上哪些地方包含了指针,
因为栈空间不属于arena区域, 栈空间的指针信息将会在函数信息里面.
另外, GC在分配对象时也需要根据对象的类型设置bitmap区域, 来源的指针信息将会在类型信息里面.


总结起来有以下GC Bitmap：
- bitmap区域：涵盖了arena区域，使用2bit表示一个指针大小的内存。
- 函数信息：涵盖了函数的栈空间，使用1 bit表示一个指针大小的内存
- 类型信息：在份额皮对象时会复制到bitmap区域，使用1 bit表示一个指针大小的内存



#### Span
span是用于分配对象的区块, 下图是简单说明了Span的内部结构

![https://images2017.cnblogs.com/blog/881857/201711/881857-20171122165711883-1079047912.png](https://images2017.cnblogs.com/blog/881857/201711/881857-20171122165711883-1079047912.png)

通常一个span包含了多个大小相同的元素，一个元素会保存一个对象，除非：
- span用于保存大对象，这种情况span只有一个元素
- span用于保存绩效对象且不包含指针的对象，这种情况span会用一个元素保存多个对象。


span中有个freeindex标记下一次分配对象时应该开始搜索的地址，分配后freeindex会增加，在freeindex之前的元素都是已分配的，在freeindex之后的元素有可能已分配，也有可能未分配。

span每次GC以后都可能会回收掉一些元素, allocBits用于标记哪些元素是已分配的, 哪些元素是未分配的.
使用freeindex + allocBits可以在分配时跳过已分配的元素, 把对象设置在未分配的元素中,

但因为每次都去访问allocBits效率会比较慢, span中有一个整数型的allocCache用于缓存freeindex开始的bitmap, 缓存的bit值与原值相反.

gcmarkBits用于在gc时标记哪些对象存活, 每次gc以后gcmarkBits会变为allocBits.

需要注意的是span结构本身的内存是从系统分配的, 上面提到的spans区域和bitmap区域都只是一个索引


#### span的类型
span根据大小可以分为67个类型

span中的元素大小是8 byte, span本身占1页也就是8K, 一共可以保存1024个对象

在分配对象时, 会根据对象的大小决定使用什么类型的span,
例如16 byte的对象会使用span 2, 17 byte的对象会使用span 3, 32 byte的对象会使用span 3.

有人可能会注意到, 上面 **最大的span的元素大小是32K**, 那么分配超过32K的对象会在哪里分配呢?
超过32K的对象称为"大对象", 分配大对象时, 会直接从heap分配一个特殊的span,
这个特殊的span的类型(class)是0, 只包含了一个大对象, span的大小由对象的大小决定.


特殊的span加上的66个标准的span, 一共组成了67个span类型.


#### span的位置
P是一个虚拟的资源, 同一时间只能有一个线程访问同一个P, 所以P中的数据不需要锁.
为了分配对象时有更好的性能, 各个P中都有span的缓存(也叫mcache), 缓存的结构如下:

![https://images2017.cnblogs.com/blog/881857/201711/881857-20171122165724540-2110504561.png](https://images2017.cnblogs.com/blog/881857/201711/881857-20171122165724540-2110504561.png)

各个P中按span类型的不同，有67*2=134个span的缓存。

其中scan和noscan的区别在于：
- 如果对象包含了指针，分配对象时会使用scan的span.
- 如果对象不包含指针，分配对象时会使用noscan的span。

把span分为scan和noscan的意义在于，gc扫描对象的时候对于noscan的span可以不去查看bitmap区域来标记子对象，这样可以大幅提升标记的效率。

在分配对象时将会从以下的位置获取适合的span用于分配：
- 首先从p的缓存(mcache)获取，如果有缓存的span并且未满则使用，这个步骤不需要锁
- 然后从全局缓存(mcentral)获取，如果获取成功则设置到P，这个步骤需要锁
- 最后从mheap获取，获取后设置到全局缓存，这个步骤需要锁

在P中缓存span的做法跟CoreCLR中线程缓存分配上下文(Allocation Context)的做法相似,
都可以让分配对象时大部分时候不需要线程锁, 改进分配的性能.

## 分配对象的处理
#### 分配对象的流程
go从堆分配对象时会调用newobject函数，这个函数的流程大致如下：

![https://images2017.cnblogs.com/blog/881857/201711/881857-20171122165733821-1250658446.png](https://images2017.cnblogs.com/blog/881857/201711/881857-20171122165733821-1250658446.png)

首先会检查GC是否在工作中, 如果GC在工作中并且当前的G分配了一定大小的内存则需要协助GC做一定的工作,
这个机制叫GC Assist, 用于防止分配内存太快导致GC回收跟不上的情况发生.


之后会判断是小对象还是大对象, 如果是大对象则直接调用largeAlloc从堆中分配,
如果是小对象分3个阶段获取可用的span, 然后从span中分配对象:
- 首先从P的缓存(mcache)获取
- 然后从全局缓存(mcentral)获取，全局缓存中有可用的span的列表
- 最后从mheap获取，mheap中也有span的自由列表，如果都获取失败则从arena区域分配。


这三个阶段纤细图解：

![https://images2017.cnblogs.com/blog/881857/201711/881857-20171122165741149-1015705312.png](https://images2017.cnblogs.com/blog/881857/201711/881857-20171122165741149-1015705312.png)

#### 数据类型的定义
分配对象涉及的数据类型包含：
- p
- m
- g
- mspan 用于分配对象的区块
- mcentral 全局的mspan缓存，一共有67*2=134个
- mheap 用于管理heap的对象，全局只有一个


## 回收对象的处理
#### 回收对象的流程
Go的GC是并行GC,也就是GC的大部分处理和普通的go代码是同时运行的，这让go的gc流程比较复杂。

首先gc有四个阶段，它们分别是：
- sweep Termination：对未清扫的span进行清扫，只有上一轮的GC的清扫工作完成才可以开始新一轮的gc
- mark 扫描所有根对象，和根对象可以到达的所有对象，标记它们不被回收。
- mark termination： 完成标记工作，重新扫描部分根对象（要求STW）
- Sweep：按标记结果清扫span

下图是比较完整的gc流程，并按颜色对这四个阶段进行了分类：

![https://images2017.cnblogs.com/blog/881857/201711/881857-20171122165749274-1840348396.png](https://images2017.cnblogs.com/blog/881857/201711/881857-20171122165749274-1840348396.png)


在GC过程中会有两种后台任务(G), 一种是标记用的后台任务, 一种是清扫用的后台任务.
标记用的后台任务会在需要时启动, 可以同时工作的后台任务数量大约是P的数量的25%, 也就是go所讲的让25%的cpu用在GC上的根据.
清扫用的后台任务在程序启动时会启动一个, 进入清扫阶段时唤醒.

目前整个GC流程会进行两次STW(Stop The World), 第一次是Mark阶段的开始, 第二次是Mark Termination阶段.
第一次STW会准备根对象的扫描, 启动写屏障(Write Barrier)和辅助GC(mutator assist).
第二次STW会重新扫描部分根对象, 禁用写屏障(Write Barrier)和辅助GC(mutator assist).
需要注意的是, 不是所有根对象的扫描都需要STW, 例如扫描栈上的对象只需要停止拥有该栈的G.

> 从go 1.9开始, 写屏障的实现使用了Hybrid Write Barrier, 大幅减少了第二次STW的时间.


#### gc的触发条件

gc在满足一定条件后会被触发，触发条件有以下几种：
- gcTriggerAlways：强制触发gc
- gcTriggerHeap：当前分配的内存达到一定值就触发gc
- gcTriggerTime：当一定时间没有执行过gc就触发gc
- gcTriggerCycle：要求启动新一轮的gc，已启动过则跳过，手动触发gc的runtime.GC()，会使用这个条件。


触发条件的判断在gctrigger的test函数.
其中gcTriggerHeap和gcTriggerTime这两个条件是自然触发的, gcTriggerHeap的判断代码如下:
```golang
return memstats.heap_live >= memstats.gc_trigger
```
heap_live的增加在上面对分配器的代码分析中可以看到, 当值达到gc_trigger就会触发GC, 那么gc_trigger是如何决定的?
gc_trigger的计算在gcSetTriggerRatio函数中, 公式是:
```
trigger = uint64(float64(memstats.heap_marked) * (1 + triggerRatio))
```

heap_live的增加在上面对分配器的代码分析中可以看到，当值达到gc_trigger就会触发gc，那么gc_trigger是如何决定的？

```
trigger = uint64(float64(memstats.heap_marked) * (1 + triggerRatio))
```

当前标记存活的大小乘以1+系数triggerRatio，就是下次出发gc需要的分量。

triggerRatio在每次gc后都会调整，计算


#### 三色的定义（黑、灰、白）
“三色”的概念可以简单的理解为：
- 黑色：对象在这次gc中已标记，且这个对象包含的子对象也已标记
- 灰色：对象在这次gc中已标记，且这个对象包含的子对象未标记
- 白色：对象在这次gc中未标记

在go内部对象并没有保存颜色的属性, 三色只是对它们的状态的描述,
- 白色的对象在它所在的span的gcmarkBits中对应的bit为0,
- 灰色的对象在它所在的span的gcmarkBits中对应的bit为1, 并且对象在标记队列中,
- 黑色的对象在它所在的span的gcmarkBits中对应的bit为1, 并且对象已经从标记队列中取出并处理.

gc完成后, gcmarkBits会移动到allocBits然后重新分配一个全部为0的bitmap, 这样黑色的对象就变为了白色.


#### 写屏障（write barrier）
因为go支持并行GC, GC的扫描和go代码可以同时运行, 这样带来的问题是GC扫描的过程中go代码有可能改变了对象的依赖树,
例如开始扫描时发现根对象A和B, B拥有C的指针, GC先扫描A, 然后B把C的指针交给A, GC再扫描B, 这时C就不会被扫描到.
为了避免这个问题, go在GC的标记阶段会启用写屏障(Write Barrier).

启用了写屏障(Write Barrier)后, 当B把C的指针交给A时, GC会认为在这一轮的扫描中C的指针是存活的,
即使A可能会在稍后丢掉C, 那么C就在下一轮回收.
写屏障只针对指针启用, 而且只在GC的标记阶段启用, 平时会直接把值写入到目标地址.


#### 辅助gc（mutator assist）
为了防止heap增速太快, 在GC执行的过程中如果同时运行的G分配了内存, 那么这个G会被要求辅助GC做一部分的工作.
在GC的过程中同时运行的G称为"mutator", "mutator assist"机制就是G辅助GC做一部分工作的机制.

辅助GC做的工作有两种类型, 一种是标记(Mark), 另一种是清扫(Sweep).






参考文献：

- [https://www.cnblogs.com/zkweb/p/7880099.html](https://www.cnblogs.com/zkweb/p/7880099.html)

