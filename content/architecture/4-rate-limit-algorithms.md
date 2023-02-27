---
title: "4 Rate Limit Algorithms 4种限流算法"
date: 2023-02-25T23:39:08+08:00
keywords: ["architecture"]
categories: ["architecture"]
tags: ["architecture"]
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

限流算法是一种限制瞬时流量的有效手段，它一般被设计在网关层中。

下面介绍4种常用的限流算法：

- 固定时间窗口(计数器)算法
- 滑动时间窗口算法
- 漏桶算法
- 令牌桶算法

#### 固定窗口算法（Fixed Window）

基本思想是：在固定时间窗口内对请求数进行统计，然后与阈值比较确定是否进行限流，一旦到了时间临界点，就将计数器清零。

| 时间窗口 | 请求计数 | 丢弃 |
|----|-----|-----|
| 12:01:00 ~ 12:02:00| 100| 0 |
| 12:02:00 ~ 12:03:00| 200| 100 |
| 12:03:00 ~ 12:04:00| 150| 50 |
|...|...|...|

算法缺陷：

- 可能存在在某个时间窗口前90%时间里没有请求，所有的请求都集中在最后10%，这个在该算法中是允许的，然后在下一个时间窗口的前10%时间里又有大量请求，这时在第一个窗口的最后10%到第二个窗口的前10%时间内就有大量的请求，如果量大到一定程度，系统可能承受不住，导致系统崩溃

| 时间窗口 | 请求计数 | 丢弃 |
|----|-----|-----|
| 12:01:00 ~ 12:01:58| 0| 0 |
| 12:01:59 ~ 12:02:00| 200| 100 |
| 12:02:00 ~ 12:02:01| 150| 50 |
| 12:02:01 ~ 12:03:00| 100 | 0 |
|...|...|...|

如上，时间12:01:59~12:02:01 已经发送了200个请求

**固定时间窗口算法无法应对突发瞬时流量，不过实现简单**

代码实现：

```go

type FixedWindowRateLimiter struct {
 threshold int           `json:"threshold"` // 阈值
 stime     time.Time     `json:"stime"`     // 开始时间
 interval  time.Duration `json:"interval"`  // 时间窗口
 counter   int           `json:"counter"`   // 当前计数
 lock      sync.Mutex
}

func NewFixedWindowRateLimiter(threshold int, interval time.Duration) *FixedWindowRateLimiter {

 return &FixedWindowRateLimiter{
  threshold: threshold,
  stime:     time.Now(),
  interval:  interval,
  counter:   threshold - 1, // 让其处于下一个时间窗口开始的时间临界点
 }
}

func (l *FixedWindowRateLimiter) Allow() bool {
 l.lock.Lock()
 defer l.lock.Unlock()

 // 判断收到请求数是否达到阈值
 if l.counter == l.threshold-1 {
  now := time.Now()
  // 达到阈值后，判断是否是请求窗口内
  if now.Sub(l.stime) >= l.interval {
   // 重新计数
   l.Reset()
   return true
  }
  // 丢弃多余的请求
  return false
 } else {
  l.counter++
  return true
 }
}

func (l *FixedWindowRateLimiter) Reset() {
 l.counter = 0
 l.stime = time.Now()
}

```

测试代码：

```go
func main() {
 limit := NewFixedWindowRateLimiter(5, 1*time.Second)

 http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
  if limit.Allow() {
   w.Write([]byte("hello world"))
   log.Printf("hello")
  }
 })

 http.ListenAndServe(":8888", nil)
}
```

然后使用ab测试

```sh
ab -n 50 -c 20 http://localhost:8888/
```

#### 滑动窗口算法（Sliding Window）

基本思想是：一个较大的时间窗口内细分成多个小窗口，大窗口按照时间顺序每次向后移动一个小窗口，并保证每次大窗口内的请求总数不超过阈值。

这种算法比固定时间窗口算法流量曲线更平滑。

算法缺陷：
滑动窗口是对固定窗口算法的一种改进，但是并没有真正解决固定窗口的临界突发瞬时大流量问题。

代码实现：

```go
type slot struct {
 timestamp time.Time `json:"timestamp"`
 counter   int       `json:"counter"`
}

type SlidingWindowRateLimiter struct {
 lock         sync.Mutex
 numSlots     int           `json:"numSlots"`     // 子窗口数量
 threshold    int           `json:"threshold"`    // 阈值
 slotInterval time.Duration `json:"slotInterval"` // 子窗口时间长度
 winInterval  time.Duration `json:"winInterval"`  // 大窗口时间长度
 slots        []*slot       `json:"slots"`        // 子窗口切片
}

func NewSlidingWindowRateLimiter(slotInterval, winInterval time.Duration, threshold int) *SlidingWindowRateLimiter {
 numSlots := int(winInterval / slotInterval)
 return &SlidingWindowRateLimiter{
  numSlots:     numSlots,
  threshold:    threshold,
  slotInterval: slotInterval,
  winInterval:  winInterval,
 }
}

func (l *SlidingWindowRateLimiter) Allow() bool {
 l.lock.Lock()
 defer l.lock.Unlock()

 now := time.Now()
 // 已经过期的slot移出时间窗
 invalidOffset := -1
 for i, s := range l.slots {
  if s.timestamp.Add(l.winInterval).After(now) {
   break
  }
  invalidOffset = i
 }
 if invalidOffset > -1 {
  l.slots = l.slots[invalidOffset+1:]
 }

 // 判断请求是否达到阈值
 var allowed bool
 if l.count() < l.threshold {
  allowed = true
 }

 // 记录这次的请求
 lastSlot := &slot{}
 if len(l.slots) > 0 {
  lastSlot = l.slots[len(l.slots)-1]
  if lastSlot.timestamp.Add(l.slotInterval).Before(now) {
   // 如果当前时间已经超过最后时间插槽的跨度，那么新建一个时间插槽
   lastSlot = &slot{timestamp: now, counter: 1}
   l.slots = append(l.slots, lastSlot)
  } else {
   lastSlot.counter++
  }
 } else {
  lastSlot = &slot{timestamp: now, counter: 1}
  l.slots = append(l.slots, lastSlot)
 }

 return allowed
}

func (l *SlidingWindowRateLimiter) count() int {
 count := 0
 for _, s := range l.slots {
  count += s.counter
 }
 return count
}

```

测试代码：

```go
func main() {
 limit := NewSlidingWindowRateLimiter(100*time.Millisecond, 1*time.Second, 5)

 http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
  if limit.Allow() {
   w.Write([]byte("hello world"))
   log.Printf("hello")
  }
 })

 http.ListenAndServe(":8888", nil)
}
```

然后使用ab测试

```sh
ab -n 50 -c 20 http://localhost:8888/
```

#### 漏桶算法（Leaky Bucket）

基本思想是：漏桶算法通过一个固定容量的桶，控制进入桶中的请求总数，然后以一定速率从桶中取出请求进行处理，如果桶已经满了，则直接丢弃请求。

适用场景：
漏桶算法是流量最均衡的限流算法，可以用于流量整型。

算法缺陷：
漏桶算法因为是先进先出队列，在突发瞬时大流量情况下，会出现大量请求失败情况，不适合抢购，热点事件等场景

代码实现：

```go
type LeakyBucketRateLimiter struct {
 capacity   float64 `json:"capacity"`   // 桶的容量
 water      float64 `json:"water"`      // 当前桶中水量
 flowRate   float64 `json:"flowRate"`   // 每秒漏桶流速
 lastLeakMs int64   `json:"lastLeakMs"` // 上次漏水毫秒数
 lock       sync.Mutex
}

func NewLeakyBucketRateLimiter(flowRate, capacity float64) *LeakyBucketRateLimiter {
 return &LeakyBucketRateLimiter{
  capacity:   capacity,
  flowRate:   flowRate,
  water:      capacity + 1, // 设置起始边界
  lastLeakMs: time.Now().UnixNano() / 1e6,
 }
}

func (l *LeakyBucketRateLimiter) Allow() bool {
 l.lock.Lock()
 defer l.lock.Unlock()

 // 获取当前时间
 now := time.Now().UnixNano() / 1e6
 // 计算这段时间流出的水量：
 outflowWater := (float64(now - l.lastLeakMs)) * l.flowRate / 1000
 // 计算水量： 桶的当前水量 - 流出的水量
 l.water = math.Max(0, l.water-outflowWater)
 l.lastLeakMs = now
 if l.water < l.capacity {
  // 当前水量 小于 桶容量，允许通过
  l.water++
  return true
 } else {
  // 当前水量 不小于 桶容量，不允许通过
  return false
 }
}

```

测试代码：

```go
func main() {
 limit := NewLeakyBucketRateLimiter(5, 10)

 http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
  if limit.Allow() {
   w.Write([]byte("hello world"))
   log.Printf("hello")
  }
 })

 http.ListenAndServe(":8888", nil)
}
```

然后使用ab测试

```sh
ab -n 50 -c 20 http://localhost:8888/
```

#### 令牌桶算法（Token Bucket）

基本思想是：令牌桶相当于反向漏桶算法，即以固定速率生成令牌放入固定容量的桶中，每个请求从桶中获取到令牌就允许执行，没有获取到就丢弃。

适用场景：
令牌桶算法弥补了漏桶算法无法应对突发大流量问题，即可以针对突发大流量进行限流

代码实现：

```go
type TokenBucketRateLimiter struct {
 capacity       float64 `json:"capacity"`       // 桶的容量
 tokens         float64 `json:"tokens"`         // 当前桶中的令牌数
 genTokenRate   float64 `json:"genTokenRate"`   // 每秒生成的令牌速率
 lastGenTokenMs int64   `json:"lastGenTokenMs"` // 上次生成令牌的毫秒数
 lock           sync.Mutex
}

func NewTokenBucketRateLimiter(genTokenRate, capacity float64) *TokenBucketRateLimiter {
 return &TokenBucketRateLimiter{
  genTokenRate:   genTokenRate,
  capacity:       capacity,
  tokens:         0,
  lastGenTokenMs: time.Now().UnixNano() / 1e6,
 }
}

func (l *TokenBucketRateLimiter) Allow() bool {
 l.lock.Lock()
 defer l.lock.Unlock()

 now := time.Now().UnixNano() / 1e6
 // 计算两个时间内生成的令牌数
 tokens := (float64(now - l.lastGenTokenMs)) * l.genTokenRate / 1000
 // 计算当前桶内令牌数
 l.tokens = math.Min(l.capacity, l.tokens+tokens)
 l.lastGenTokenMs = now
 if l.tokens > 0 {
  // 获取到令牌，允许执行
  l.tokens--
  return true
 } else {
  // 没有令牌，不允许执行
  return false
 }
}
```

测试代码：

```go
func main() {
 limit := NewTokenBucketRateLimiter(1, 10)

 http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
  if limit.Allow() {
   w.Write([]byte("hello world"))
   log.Printf("hello")
  }
 })

 http.ListenAndServe(":8888", nil)
}
```

然后使用ab测试

```sh
ab -n 50 -c 20 http://localhost:8888/
```

#### 分布式限流

具体实现是通过redis实现，算法可以上述四种限流算法
