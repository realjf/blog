---
title: "按顺序打印自然数字 Print Natural Number"
date: 2021-03-26T15:25:15+08:00
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

### 题目：按照顺序打印自然数字

```golang
package main

import (
	"fmt"
	"sync"
)

var (
	wg sync.WaitGroup
)

func print(ch *chan int, i int) {
	defer wg.Done()
	*ch <- i
}

func main() {
  maxInt := 7
	wg.Add(maxInt)

	ch := make(chan int)
	for i := 0; i < maxInt; i++ {
		go print(&ch, i)
		fmt.Println(<-ch) // 这里卡住等待第i个goroutine运行，然后打印
	}
	
	wg.Wait()
	fmt.Println("done")
}
```

