---
title: "Go内存泄漏 Golang Memory Leak"
date: 2021-04-09T13:57:59+08:00
keywords: ["golang"]
categories: ["golang"]
tags: ["golang"]
series: [""]
draft: false
toc: false
related:
  threshold: 50
  includeNewer: true
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

## 环境
- go v1.14.4

### 什么是 Pprof
首先，不得不提的就是go分析利器pprof。pprof记录程序在运行过程中的cpu使用情况、内存使用情况、
goroutine运行情况、阻塞状况等，是定位bug和性能分析的利器。

### 如何开启pprof
go中有两个地方有：

- net/http/pprof
- runtime/pprof

差别只是runtime/pprof通过封装暴露http端口后就是net/http/pprof

开启pprof很简单，只需导入net/http/pprof包，并开启一个goroutine去监听http端口6060就可以了，具体代码如下：
```golang
package main


import (
	"fmt"
	"net/http"
	_ "net/http/pprof"
	
	"github.com/gorilla/mux"
	"time"
	"log"
)

func hello(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("hello world"))
}

func main() {
	go func() {
		ip := ":6060"
		if err := http.ListenAndServe(ip, nil); err != nil {
			fmt.Printf("start pprof failed on %s\n", ip)
		}
	}()

	r := mux.NewRouter()
	r.HandleFunc("/hello", hello)
	srv := &http.Server{
        Handler:      r,
        Addr:         ":8080",
        WriteTimeout: 15 * time.Second,
        ReadTimeout:  15 * time.Second,
    }

    log.Fatal(srv.ListenAndServe())
}

```
运行之后，可以在浏览器中打开ip:6060/debug/pprof页面，其中的信息大致如下：

- allocs：所有过去内存分配的抽样
- block：groutine阻塞的堆栈信息
- cmdline：当前程序的命令行调用
- groutine：所有goroutine的信息
- heap: 活动对象的内存分配抽样。在获取堆样本之前，可以指定gc GET参数来运行gc
- mutex: 争用互斥锁持有者的堆栈跟踪
- profile: CPU配置文件。您可以在seconds GET参数中指定持续时间。获取概要文件后，使用go tool pprof命令来调查概要文件。
- threadcreate: 导致创建新操作系统线程的堆栈跟踪
- trace: 当前程序的执行痕迹。您可以在seconds GET参数中指定持续时间。获取跟踪文件后，使用go tool trace命令来调查跟踪。
- full groutine stack dump: goroutine调用栈信息


### 命令行交互方式访问
```sh
# 可以获取指定的profile文件，此命令会发起http请求，并下载数据到本地，之后进入交互模式
go tool pprof url
# url可以是：http://127.0.0.1:6060/debug/pprof/heap之类
# 进入交互终端后，可以执行help查看命令说明
# 如：go tool pprof http://127.0.0.1:6060/debug/pprof/goroutine之后运行top命令，结果如下：
(pprof) top
Showing nodes accounting for 4, 100% of 4 total
Showing top 10 nodes out of 26
      flat  flat%   sum%        cum   cum%
         2 50.00% 50.00%          2 50.00%  runtime.gopark
         1 25.00% 75.00%          1 25.00%  net/http.(*connReader).backgroundRead
         1 25.00%   100%          1 25.00%  runtime/pprof.writeRuntimeProfile
         0     0%   100%          2 50.00%  internal/poll.(*FD).Accept
         0     0%   100%          2 50.00%  internal/poll.(*FD).acceptOne
         0     0%   100%          2 50.00%  internal/poll.(*ioSrv).ExecIO
         0     0%   100%          2 50.00%  internal/poll.(*pollDesc).wait
         0     0%   100%          2 50.00%  internal/poll.runtime_pollWait
         0     0%   100%          1 25.00%  main.main
         0     0%   100%          1 25.00%  main.main.func1

# - flat: 给定函数上运行goroutine数量
# - flat%: 给定函数上goroutine运行数量总占比
# - sum%: 给定函数累计goroutine数量总占比
# - cum: 当前函数加上它之前的调用中goroutine运行总数量
# - cum%: 当前函数及之前调用中goroutine数量总占比
# 最后一列是函数名称
```

运行go tool pprof http://127.0.0.1:6060/debug/pprof/heap命令可以加上一些参数：

- -inuse_space: 分析应用程序的常驻内存占用情况，通常用来检测有没有不符合预期的内存 对象引用
- -alloc_objects: 分析应用程序的内存临时分配情况

```sh
# go tool pprof http://127.0.0.1:6060/debug/pprof/goroutine之后运行list main命令，结果如下：
(pprof) list main
Total: 4
ROUTINE ======================== main.main in F:\shared\gopath\src\test_pprof\main.go
         0          1 (flat, cum) 25.00% of Total
         .          .     30:        Addr:         ":8080",
         .          .     31:        WriteTimeout: 15 * time.Second,
         .          .     32:        ReadTimeout:  15 * time.Second,
         .          .     33:    }
         .          .     34:
         .          1     35:    log.Fatal(srv.ListenAndServe())
         .          .     36:}
ROUTINE ======================== main.main.func1 in F:\shared\gopath\src\test_pprof\main.go
         0          1 (flat, cum) 25.00% of Total
         .          .     16:}
         .          .     17:
         .          .     18:func main() {
         .          .     19:   go func() {
         .          .     20:           ip := ":6060"
         .          1     21:           if err := http.ListenAndServe(ip, nil); err != nil {
         .          .     22:                   fmt.Printf("start pprof failed on %s\n", ip)
         .          .     23:           }
         .          .     24:   }()
         .          .     25:
         .          .     26:   r := mux.NewRouter()
ROUTINE ======================== runtime.main in E:\Go\src\runtime\proc.go
         0          1 (flat, cum) 25.00% of Total
         .          .    198:           // A program compiled with -buildmode=c-archive or c-shared
         .          .    199:           // has a main, but it is not executed.
         .          .    200:           return
         .          .    201:   }
         .          .    202:   fn := main_main // make an indirect call, as the linker doesn't know the address of the main package when laying down the runtime
         .          1    203:   fn()
         .          .    204:   if raceenabled {
         .          .    205:           racefini()
         .          .    206:   }
         .          .    207:
         .          .    208:   // Make racy client program work: if panicking on
```
list main查看main函数的代码以及该函数每行代码的指标信息，当然list参数可以进行模糊匹配。

```sh
# traces命令可以打印所有调用栈信息
(pprof) traces
Type: goroutine
Time: Apr 9, 2021 at 2:46pm (CST)
-----------+-------------------------------------------------------
         1   runtime.gopark
             runtime.netpollblock
             internal/poll.runtime_pollWait
             internal/poll.(*pollDesc).wait
             internal/poll.(*ioSrv).ExecIO
             internal/poll.(*FD).acceptOne
             internal/poll.(*FD).Accept
             net.(*netFD).accept
             net.(*TCPListener).accept
             net.(*TCPListener).Accept
             net/http.(*Server).Serve
             net/http.(*Server).ListenAndServe
             main.main
             runtime.main
-----------+-------------------------------------------------------
         1   runtime.gopark
             runtime.netpollblock
             internal/poll.runtime_pollWait
             internal/poll.(*pollDesc).wait
             internal/poll.(*ioSrv).ExecIO
             internal/poll.(*FD).acceptOne
             internal/poll.(*FD).Accept
             net.(*netFD).accept
             net.(*TCPListener).accept
             net.(*TCPListener).Accept
             net/http.(*Server).Serve
             net/http.(*Server).ListenAndServe
             net/http.ListenAndServe
             main.main.func1
-----------+-------------------------------------------------------
         1   net/http.(*connReader).backgroundRead
-----------+-------------------------------------------------------
         1   runtime/pprof.writeRuntimeProfile
             runtime/pprof.writeGoroutine
             runtime/pprof.(*Profile).WriteTo
             net/http/pprof.handler.ServeHTTP
             net/http/pprof.Index
             net/http.HandlerFunc.ServeHTTP
             net/http.(*ServeMux).ServeHTTP
             net/http.serverHandler.ServeHTTP
             net/http.(*conn).serve
-----------+-------------------------------------------------------

```

### pprof可视化界面
首先，运行go tool pprof http://127.0.0.1:6060/debug/pprof/profile获取profile文件

启动可视化界面方法：
```sh
# 方法一
go tool pprof -http=:8080 profile

# 方法二
go tool pprof profile
(pprof) web
```

### 内存泄漏
使用监控工具可以发现：随着时间的推进，内存的占用率在不断的提高，这是内存泄露的最明显现象。



### 参考文献
- [https://software.intel.com/content/www/us/en/develop/blogs/debugging-performance-issues-in-go-programs.html](https://software.intel.com/content/www/us/en/develop/blogs/debugging-performance-issues-in-go-programs.html)
- [https://studygolang.com/articles/20519](https://studygolang.com/articles/20519)
- [https://dave.cheney.net/high-performance-go-workshop/gopherchina-2019.html](https://dave.cheney.net/high-performance-go-workshop/gopherchina-2019.html)