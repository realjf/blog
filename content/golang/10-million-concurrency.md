---
title: "百万并发实现 10 Million Concurrency"
date: 2021-03-26T17:49:20+08:00
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
// 实现百万并发
package main 

import (
	"fmt"
	"time"
	"runtime"
)

type Score struct {
	Num int
}

func (s *Score) Do() {
	fmt.Println("num:", s.Num)
	time.Sleep(1 * 1 * time.Second)
}


// job
type Job interface {
	Do()
}

// worker
type Worker struct {
	JobQueue chan Job
}

func NewWorker() Worker {
	return Worker{JobQueue: make(chan Job)}
}

func (w Worker) Run(wq chan chan Job) {
	go func() {
		for {
			wq <- w.JobQueue
			select {
			case job := <-w.JobQueue:
				job.Do()
			}
		}
	}()
}

// workerpool
type WorkerPool struct {
	workerlen int
	JobQueue chan Job
	WorkerQueue chan chan Job
}

func NewWorkerPool(workerlen int) *WorkerPool {
	return &WorkerPool{
		workerlen: workerlen,
		JobQueue: make(chan Job),
		WorkerQueue: make(chan chan Job, workerlen),
	}
}

func (wp *WorkerPool) Run() {
	fmt.Println("init worker")
	for i := 0; i < wp.workerlen; i++ {
		worker := NewWorker()
		worker.Run(wp.WorkerQueue)
	}

	go func() {
		for {
			select {
			case job := <- wp.JobQueue:
				worker := <- wp.WorkerQueue
				worker <- job
			}
		}
	}()
}

func main() {
	num := 100 * 100 * 20
	// debug.SetMaxThreads(num + 1000) // 设置最大线程数

	p := NewWorkerPool(num)
	p.Run()

	datanum := 100 * 100 * 100 * 100
	go func() {
		for i := 1; i <= datanum; i++ {
			sc := &Score{Num: i}
			p.JobQueue <- sc
		}
	}()

	for {
		fmt.Println("runtime.NumGoroutine(): ", runtime.NumGoroutine())
		time.Sleep(2 * time.Second)
	}

}
```