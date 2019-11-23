---
title: "golang性能分析利器之Pprof"
date: 2019-03-19T15:14:16+08:00
keywords: ["golang", "pprof", "golang性能分析"]
categories: ["golang"]
tags: ["golang", "pprof", "golang性能分析"]
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

pprof是golang程序一个性能分析的工具，可以查看堆栈、cpu信息等

pprof有2个包：net/http/pprof以及runtime/pprof

二者之间的关系：net/http/pprof包只是使用runtime/pprof包来进行封装了一下，并在http端口上暴露出来


#### 性能分析利器 pprof
go本身提供的工具链有：
- runtime/pprof：采集程序的运行数据进行分析
- net/http/pprof：采集HTTP Server的运行时数据进行分析

pprof以profile.proto读取分析样本的集合，并生成报告以可视化并帮助分析数据

> profile.proto是一个Protocol Buffer v3的描述文件，它描述了一组callstack和symbolization信息，作用是表示统计分析的一组采样的调用栈，是很常见的stacktrace配置文件格式


#### 使用方式
- Report generation：报告生成
- Interactive terminal use：交互式终端使用
- Web interface：Web界面

##### 1. web服务器方式
假如你的go呈现的是用http包启动的web服务器，当想要看web服务器的状态时，选择【net/http/pprof】，使用方法如下：
```golang
"net/http"
_ "net/http/pprof"
```

查看结果：通过访问：http://domain:port/debug/pprof查看当前web服务的状态
##### 2. 服务进程
如果你go程序是一个服务进程，同样可以选择【net/http/pprof】包，然后开启另外一个goroutine来开启端口监听

```golang
// 远程获取pprof数据
go func() {
    log.Println(http.ListenAndServe("localhost:8080", nil))
}
```

##### 3. 应用程序
如果你的go程序只是一个应用程序，那就直接使用runtime/pprof包，具体用法是用pprof.StartCPUProfile和pprof.StopCPUProfile。
```golang
var cpuprofile = flag.String("cpuprofile", "", "write cpu profile to file")

func main() {
    flag.Parse()
    if *cpuprofile != "" {
        f, err := os.Create(*cpuprofile)
        if err != nil {
            log.Fatal(err)
        }
        pprof.StartCPUProfile(f)
        defer pprof.StopCPUProfile()
    }
}
```


#### 作用场景
- CPU Profiling：CPU分析，按照一定的频率采集所监听的应用程序CPU（含寄存器）的使用情况，可用于确定应用程序消耗cpu周期时花费时间的位置
- Memory Profiling：内存分析，在应用程序进行堆分配时记录堆栈跟踪，用于监视当前和历史内存使用情况，以及检查内存泄漏。
- Block Profiling：阻塞分析，记录goroutine阻塞等待同步（包括定时器通道）的位置
- Mutex Profiling：互斥锁分析，报告互斥锁的竞争情况


### 分析
#### 通过web界面分析
```sh
http://localhost:8080/debug/pprof/
```
结果如下：
```
/debug/pprof/

Types of profiles available:
Count	Profile
1	allocs
0	block
0	cmdline
14	goroutine
1	heap
0	mutex
0	profile
11	threadcreate
0	trace
full goroutine stack dump 
```
- allocs：过去所有的内存分配采样
- block：Stack traces that led to blocking on synchronization primitives
- cmdline：当前程序的命令行调用
- goroutine：所有当前goroutine堆栈跟踪
- heap：所有存活对象的内存分配采样。你可以在堆采样时指定gc GET参数来运行垃圾回收
- mutex：争用互斥锁的拥有者堆栈跟踪
- profile：CPU profile. You can specify the duration in the seconds GET parameter. After you get the profile file, use the go tool pprof command to investigate the profile.
- threadcreate：引起创建新的操作系统线程的堆栈跟踪
- trace：对当前程序执行的跟踪。可以在seconds get参数中指定持续时间。获取跟踪文件后，使用go tool trace命令调查跟踪
- full groutine stack dump：


#### 实例分析
```golang
package main

import (
    "flag"
    "log"
    "net/http"
    _ "net/http/pprof"
    "sync"
    "time"
)

func Counter(wg *sync.WaitGroup) {
    time.Sleep(time.Second)

    var counter int
    for i := 0; i < 1000000; i++ {
        time.Sleep(time.Millisecond * 200)
        counter++
    }
    wg.Done()
}

func main() {
    flag.Parse()

    //远程获取pprof数据
    go func() {
        log.Println(http.ListenAndServe("localhost:8080", nil))
    }()

    var wg sync.WaitGroup
    wg.Add(10)
    for i := 0; i < 10; i++ {
        go Counter(&wg)
    }
    wg.Wait()

    // sleep 10mins, 在程序退出之前可以查看性能参数.
    time.Sleep(60 * time.Second)
}

```


