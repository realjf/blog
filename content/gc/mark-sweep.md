---
title: "gc垃圾回收算法之一 标记-清除算法（Mark-Sweep）"
date: 2020-04-08T11:11:57+08:00
keywords: ["gc"]
categories: ["gc"]
tags: ["gc"]
series: ["gc"]
draft: true
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

### 什么是标记-清除算法？
GC标记-清理算法由标记阶段和清理阶段组成。标记阶段是把所有活动对象都做上标记的阶段。清理阶段是把没有标记的对象，即非活动对象回收的阶段。
通过这两个阶段，就可以重复利用内存空间了。

```c
mark_sweep(){
    mark_phase()
    sweep_phase()
}
```
### 标记阶段
标记阶段，首先通过根对象标记直接引用的活动对象，然后递归标记所有能通过指针数组访问到的对象。这样就能标记所有活动对象了。
利用mark_phase()函数来进行标记阶段处理
```c
mark_phase(){
    for(r : $roots)
        mark(*r)
}

# 标记函数
mark(obj){
    if(obj.mark==false)
        obj.mark = true
        for(child : children(obj))
            mark(*child)
}
```
标记阶段总结来说就是遍历所有对象并标记活动对象的过程。

> 我们在搜索对象时常使用深度优先搜索、广度优先搜索方法。


### 清除阶段

在清除阶段，collector会遍历整个堆，回收没有打上标记的对象（即垃圾），使其能再次得到利用。

```c
sweep_phase(){
    sweeping = $heap_start
    while(sweeping < $heap_end)
        if(sweeping.mark == true)
            sweeping.mark = false
        else
            sweeping.next = $free_list
            $free_list = sweeping
        sweeping += sweeping.size
}
```




