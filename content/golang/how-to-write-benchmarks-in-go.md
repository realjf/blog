---
title: "如何写go语言的基准测试？"
date: 2019-11-25T15:08:36+08:00
keywords: ["golang", "benchmarks", "基准测试"]
categories: ["golang"]
tags: ["golang", "benchmarks", "基准测试"]
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

### 简介
Go标准库中test包包含一个基准测试工具，可用于检查Go代码的性能。
接下来将介绍如何使用测试包编写一个简单的基准测试。


### 一个基准测试示例
我们以斐波那契数列计算来做测试
```go
func Fib(n int) int {
	if n < 2 {
		return n
	}
	
	return Fib(n-1) + Fib(n-2)
}
```
创建一个名为*_test.go的测试文件，我们将对计算第20个斐波那契数列值进行性能测试。
```go
func BenchmarkFib20(b  *testing.B) {
    for n := 0; n < b.N; n++ {
    	Fib(20)
    }
}
```
编写基准测试与编写测试非常相似，因为它们共享测试包中的基础结构。一些关键区别是

- 基准测试功能以Benchmark而不是Test开头
- 基准功能由测试包运行多次。 b.N的值每次都会增加，直到基准运行者对基准的稳定性感到满意为止。
- 每个基准测试必须执行b.N次测试代码。 BenchmarkFib20中的for循环将出现在每个基准测试函数中。


### 运行基准测试
我们可以使用go test -bench=. 调用基准测试
```bash
go test -bench=.

# 运行结果如下
goos: linux
goarch: amd64
pkg: test/benchmark
BenchmarkFib-4             30000             44684 ns/op
PASS
ok      test/benchmark  1.796s

```
您必须将有效的正则表达式传递给-bench，仅传递-bench是语法错误。您可以使用此属性来运行基准测试的子集

如果要跳过测试，可以通过将正则表达式传递给不匹配任何内容的-run标志来实现。我通常使用
```bash
go test -run=XXX -bench=.
```
第四行BenchmarkFib-4是迭代b.N次的最终值的平均运行时间。我这里是执行Fib(20)运行时间在44684 ns


### 各种输入的基准测试
由于原始的Fib函数是经典的递归实现，因此我们希望它会随着输入的增长而呈现指数行为。
我们可以通过使用Go标准库中非常常见的模式稍微重写基准来探索这一点

```go
func benchmarkFib(i int, b *testing.B) {
    for n := 0; n <b.N; n++{
    	Fib(i)
    }
}

func BenchmarkFib1(b *testing.B)  { benchmarkFib(1, b) }
func BenchmarkFib2(b *testing.B)  { benchmarkFib(2, b) }
func BenchmarkFib3(b *testing.B)  { benchmarkFib(3, b) }
func BenchmarkFib10(b *testing.B) { benchmarkFib(10, b) }
func BenchmarkFib20(b *testing.B) { benchmarkFib(20, b) }
func BenchmarkFib40(b *testing.B) { benchmarkFib(40, b) }
```
将benchmarkFib设置为private可避免测试驱动程序尝试直接调用它，因为其签名与func（* testing.B）不匹配将失败。
运行这套新的基准测试获得如下结果：
```bash
goos: linux
goarch: amd64
pkg: test/benchmark
BenchmarkFib-4           5000000               362 ns/op
BenchmarkFib1-4         1000000000               2.11 ns/op
BenchmarkFib2-4         300000000                5.86 ns/op
BenchmarkFib3-4         200000000                9.86 ns/op
BenchmarkFib10-4         5000000               358 ns/op
BenchmarkFib20-4           30000             44751 ns/op
BenchmarkFib40-4               2         674276614 ns/op
PASS
ok      test/benchmark  15.811s

```

除了确认我们简单的Fib函数的指数行为外，在此基准测试运行中还需要观察其他一些内容。
- 默认情况下，每个基准测试运行至少1秒。如果Benchmark函数返回时第二秒还没有过去，则b.N的值将按顺序1、2、5、10、20、50，…增加，然后函数再次运行
- 最终的BenchmarkFib40只运行了两次，每次运行的平均值不到一秒钟。由于测试程序包使用简单的平均值（在b.N上运行基准函数的总时间），因此该结果在统计上较弱。您可以使用-benchtime标志增加最短​​基准时间，以产生更准确的结果。
```bash
go test -bench=Fib40 -benchtime=20s
# 结果如下
goos: linux
goarch: amd64
pkg: test/benchmark
BenchmarkFib40-4              50         680114858 ns/op
PASS
ok      test/benchmark  34.681s

```

### 误区
上面我提到了for循环对于基准驱动程序的运行至关重要。这是错误的基准测试的两个示例
```go
func BenchmarkFibWrong(b *testing.B) {
        for n := 0; n < b.N; n++ {
                Fib(n)
        }
}

func BenchmarkFibWrong2(b *testing.B) {
        Fib(b.N)
}
```
BenchmarkFibWrong无法完成。这是因为基准测试的运行时间会随着b.N的增加而增加，而永远不会收敛于稳定值。 
BenchmarkFibWrong2同样受到影响，并且永远不会完成




