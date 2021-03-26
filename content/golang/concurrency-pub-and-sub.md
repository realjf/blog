---
title: "go并发模式 之 发布订阅模型 Concurrency Pub and Sub"
date: 2021-03-26T17:08:06+08:00
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

```golang 
package main

import (
	"fmt"
	"time"
	"sync"
	"strings"
)

type (
	subscriber chan interface{} // 订阅者
	topicFunc func(v interface{}) bool // 主题
)


type Publisher struct {
	m sync.RWMutex
	buffer int // 订阅队列缓存大小
	timeout time.Duration // 发布超时时间
	subscribers map[subscriber]topicFunc // 订阅者信息
}

// 构建一个发布者对象，可以设置发布超时时间和缓存队列长度
func NewPublisher(publishTimeout time.Duration, buffer int) *Publisher {
	return &Publisher{
		buffer: buffer,
		timeout: publishTimeout,
		subscribers: make(map[subscriber]topicFunc),
	}
}

// 添加新订阅者，订阅全部主题
func (p *Publisher) Subscirbe() chan interface{} {
	return p.SubscirbeTopic(nil)
}

// 添加一个新的订阅者，订阅过滤器筛选后的主题
func (p *Publisher) SubscirbeTopic(topic topicFunc) chan interface{} {
	ch := make(chan interface{}, p.buffer)
	p.m.Lock()
	defer p.m.Unlock()
	p.subscribers[ch] = topic

	return ch
}

// 退出订阅
func (p *Publisher) Evict(sub chan interface{}) {
	p.m.Lock()
	defer p.m.Unlock()

	delete(p.subscribers, sub)
	close(sub)
}

// 发布一个主题
func (p *Publisher) Publish(v interface{}) {
	p.m.RLock()
	defer p.m.RUnlock()

	var wg sync.WaitGroup
	for sub, topic := range p.subscribers {
		wg.Add(1)
		go p.sendTopic(sub, topic, v, &wg)
	}
	wg.Wait()
}

// 发送主题
func (p *Publisher) sendTopic(sub subscriber, topic topicFunc, v interface{}, wg *sync.WaitGroup) {
	defer wg.Done()
	if topic != nil && !topic(v) {
		return
	}

	select {
	case sub <- v:
	case <-time.After(p.timeout):
	}
}

// 关闭发布者对象
func (p *Publisher) Close() {
	p.m.Lock()
	defer p.m.Unlock()

	for sub := range p.subscribers {
		delete(p.subscribers, sub)
		close(sub)
	}
}

func main() {
	p := NewPublisher(100* time.Millisecond, 10)
	defer p.Close()

	all := p.Subscirbe()
	golang := p.SubscirbeTopic(func(v interface{}) bool {
		if s, ok := v.(string); ok {
			return strings.Contains(s, "golang")
		}
		return false
	})

	p.Publish("hello, world!")
	p.Publish("hello, golang!")

	go func(){
		for msg := range all {
			fmt.Println("all:", msg)
		}
	}()

	go func() {
		for msg := range golang {
			fmt.Println("golang:", msg)
		}
	}()

	// 运行一定时间后退出
	time.Sleep(3 * time.Second)
}
```