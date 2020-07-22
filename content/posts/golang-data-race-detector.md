---
title: "Golang 并发编程 之 数据竞态检测"
date: 2019-11-21T16:41:31+08:00
keywords: ["golang", "race", "concurrency", "竞态检测"]
categories: ["golang"]
tags: ["golang", "race", "concurrency", "竞态检测"]
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

什么是数据争用或竞态
---

数据争用是并发系统中最常见且最难调试的错误类型之一。当两个goroutine并发访问同一变量并且至少其中之一是写操作时，就会发生数据争用。

下面让我们来实际模拟一下数据争用问题。

以下示例可能导致内存崩溃和损坏的数据争用
```go
func main() {
	c := make(chan bool)
	m := make(map[string]string)
	go func() {
		m["1"] = "a"
		c <- true
	}()
	m["2"] = "b"
	<-c
	for k, v := range m {
		fmt.Println(k, v)
	}
}
```

运行go run -race main.go进行竞争检测，得到的结果如下：

```bash
#==================
WARNING: DATA RACE
Write at 0x00c00008e150 by goroutine 6:
  runtime.mapassign_faststr()
      /usr/local/go/src/runtime/map_faststr.go:202 +0x0
  main.main.func1()
      /root/go_project/src/test/race.go:9 +0x5d

Previous write at 0x00c00008e150 by main goroutine:
  runtime.mapassign_faststr()
      /usr/local/go/src/runtime/map_faststr.go:202 +0x0
  main.main()
      /root/go_project/src/test/race.go:12 +0xc6

Goroutine 6 (running) created at:
  main.main()
      /root/go_project/src/test/race.go:8 +0x97
#==================
2 b
1 a
Found 1 data race(s)
```

#### 利用build tag排除*_test.go文件加入到-race标记的构建中
```go
// +build !race

package foo

// The test contains a data race. See issue 123.
func TestFoo(t *testing.T) {
	// ...
}

// The test fails under the race detector due to timeouts.
func TestBar(t *testing.T) {
	// ...
}

// The test takes too long under the race detector.
func TestBaz(t *testing.T) {
	// ...
}
```

### 典型示例
#### 1. 循环计数器的数据争用

```go
func main() {
	var wg sync.WaitGroup
	wg.Add(5)
	for i := 0; i < 5; i++ {
		go func() {
			fmt.Println(i)
			wg.Done()
		}() // 这里没有传递值，所以所有goroutine共享i变量
	}
	wg.Wait()
}

```
上面的打印结果是55555，而不是01234

**解决方法**是，将变量作为参数传递到goroutine中
```go
func main() {
	var wg sync.WaitGroup
	wg.Add(5)
	for i := 0; i < 5; i++ {
		go func(j int) {
			fmt.Println(j)
			wg.Done()
		}(i)
	}
	wg.Wait()
}
```
#### 2. 偶然的共享变量
```go
func ParalleWrite(data []byte) chan error {
	res := make(chan error, 2)
	f1, err := os.Create("file1")
	if err != nil {
		res <- err
	}else{
		go func() {
			// 与main goroutine共享err变量，所以可能出现写冲突
			_, err = f1.Write(data)
			res <- err
			f1.Close()
		}()
	}
	f2, err := os.Create("file2")
	if err != nil {
		res <- err
	}else{
		go func() {
			// 第2次写冲突
			_, err = f2.Write(data)
			res <- err
			f2.Close()
		}()
	}
	return res
}
```
解决方法：采用新变量（利用:=声明）
```go
...
 _, err := f1.Write(data)
 ...
 _, err := f2.Write(data)
...
```

#### 3.未保护的全局变量

```go
var service map[string]net.Addr

func RegisterService(name string, addr net.Addr) {
	service[name] = addr
}

func LookupService(name string) net.Addr {
	return service[name]
}
```
解决方法是对数据进行加锁
```go
type Service struct {
	list map[string]net.Addr
	mu sync.Mutex
}

func (s *Service) RegisterService(name string, addr net.Addr) {
	s.mu.Lock()
	defer s.mu.Unlock()
	service[name] = addr
}

func (s *Service) LookupService(name string) net.Addr {
	s.mu.Lock()
	defer s.mu.Unlock()
	return service[name]
}
```

#### 4. 无保护的基本数据类型
```go
type Watchdog struct {
	last int64
}

func (w *Watchdog) KeepAlive() {
	w.last = time.Now().UnixNano()
}

func (w *Watchdog) Start() {
	go func() {
		for {
			time.Sleep(time.Second)
			if w.last < time.Now().Add(-10 * time.Second).UnixNano() {
				fmt.Println("No keepalives for 10 seconds. Dying.")
				os.Exit(1)
			}
		}
	}()
}
```
解决方法是利用原子操作sync/atomic
```go
func (w *Watchdog) KeepAlive_safe() {
	atomic.StoreInt64(&w.last, time.Now().UnixNano())
}

func (w *Watchdog) Start_safe() {
	go func() {
		for {
			time.Sleep(time.Second)
			if atomic.LoadInt64(&w.last) < time.Now().Add(-10 * time.Second).UnixNano() {
				fmt.Println("No keepalives for 10 seconds. Dying.")
				os.Exit(1)
			}
		}
	}()
}
```


