---
title: "Golang语言包性能跟踪分析工具 之 Trace 的使用"
date: 2019-11-20T11:30:01+08:00
keywords: ["golang", "go trace", "go tool", "trace"]
categories: ["golang"]
tags: ["golang", "go trace", "go tool", "trace"]
draft: true
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

要生成trace跟踪文件，需要使用runtime.trace的功能，具体代码如下
```go

func main() {
	trace.Start(os.Stderr)
	defer trace.Stop()
	
	...
}
```
生成跟踪文件
```bash
go run main.go 2> trace.out

```
启动可视化界面
```bash
go tool trace trace.out
```

trace 可视化界面具体可以分为以下几个部分

- View trace: 查看跟踪
- Goroutine analysis: goroutine分析
- Network blocking profile: 网络阻塞情况
- Synchronization blocking profile: 同步阻塞情况
- Syscall blocking profile: 系统调用阻塞情况
- Scheduler latency profile: 带哦度延迟情况
- User defined tasks: 用户自定义任务
- User defined regions: 用户自定义区域
- Minimum mutator utilization: 最低mutator利用率





