---
title: "使用数据库实现链表 Using Database to Realize Linkedlist"
date: 2020-12-09T16:03:48+08:00
keywords: ["mysql"]
categories: ["mysql"]
tags: ["mysql", "linked list"]
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

## 背景

今天遇到一个需求，在一个排队队列中，对第一个人员可以进行延后处理操作（实际是往后移动 4 位，到第 5 位），一开始想通过排序值
控制队列排序问题，但是容错性差，不能得到很好的效果，想来想去链表结构的特性对于插入删除 O(1)的性能，可以很好的解决我的问题，
所以决定通过数据库表设计来实现一个链表。

- 数据库：mysql
- 程序语言：php

## 实现

表结构简化成只有 id 和 next 指针的设计，next 指向下一个成员的 id。最后一个成员的 next 指向 0。

表结构及数值如下：

| id  | next |
| :-: | :--: |
|  1  |  3   |
|  2  |  1   |
|  3  |  4   |
|  4  |  5   |
|  5  |  6   |
|  6  |  0   |

整理成链表大致是这样的

```text
2 --> 1 --> 3 --> 4 --> 5 --> 6 --> 0
```

最后的 0 代表链表结束。

按需求，如果第一个人员延后操作，需要向后移动 4 位，步骤是这样的：

首先将队列所有人员从数据库中取出，然后在程序中按照链表结构排序，排序程序如下

```php
static public function qsort($queue)
{
    if (!$queue) {
        return $queue;
    }
    $sortQueue = [];
    $zeroNext = [];
    $ids = [];
    foreach ($queue as $v) {
        $ids[] = $v["id"];
        if ($v && $v["next"] == 0) {
            $zeroNext[$v["id"]] = $v;
            continue;
        }
        $sortQueue[$v["next"]] = $v;
    }

    $rightTail = [];
    foreach ($zeroNext as $i => $v) {
        if (isset($sortQueue[$v["id"]])) {
            // 找到正确的结尾
            $rightTail = $sortQueue[$v["next"]] = $v;
            unset($zeroNext[$i]);
            break;
        }
    }

    // 如果没有找到
    if (empty($rightTail)) {
        $rightTail = reset($zeroNext);
        // 拼接上之前的队列
        foreach ($sortQueue as $i => $v) {
            if (!in_array($i, $ids)) {
                // 需要把$i替换成$rightTail
                $v["next"] = $rightTail["id"];
                // @todo 更新到db
                // 条件：id=$v["id"]; 数据：next=$v["next"];
                $sortQueue[$v["next"]] = $v;
                unset($sortQueue[$i]);
                break;
            }
        };
        // $sortQueue[$rightTail["next"]] = $rightTail;
        foreach ($zeroNext as $i => $v) {
            if (isset($sortQueue[$v["id"]])) {
                // 找到正确的结尾
                $rightTail = $sortQueue[$v["next"]] = $v;
                unset($zeroNext[$i]);
                break;
            }
        }
    }


    // 将剩余的结尾拼接上去，按目前先后顺序
    foreach ($zeroNext as $i => $v) {
        if (!$rightTail["next"]) {
            $rightTail["next"] = $i;
            // @todo 更新到db
            if($rightTail["id"] == $i){
                // next=0
            }else{
                // next=$i
            }
        }
        $sortQueue[$i] = $rightTail;
        $rightTail = $sortQueue[$v["next"]] = $v;
    }
    $myQueue = [];
    $nextId = 0;
    // 先按照next倒序排列
    for ($i = 0; $i < count($queue); $i++) {
        $myQueue[] = $sortQueue[$nextId];
        $nextId = $sortQueue[$nextId]["id"];
        if (!$nextId) {
            break;
        }
    }
    // 反转数组即可
    return array_reverse($myQueue);
}
```

排序完成后，需要对链表进行移动操作，把第一个人员移动到第 5 位，程序实现如下：

```php
// 将第5个的next修改为这个用户的id，然后把该用户的next修改为第6个用户的id
$num = count($queue);
            if($num == 1){
                // 只有一个的时候，操作无效果
                return $queue;
            }
            if($num == 5){
                // 置于队尾
                $queue[4]["next"] = $queue[0]["id"];
                $queue[0]["next"] = 0;

                // 将修改结果保存到数据库
                mdlAccompany::instance()->updateQueue($queue[4]["id"], ["next" => $queue[4]["next"]]);
                mdlAccompany::instance()->updateQueue($queue[0]["id"], ["next" => $queue[0]["next"]]);
            }elseif($num < 5){
                // 小于5个
                $queue[$num-1]["next"] = $queue[0]["id"];
                $queue[0]["next"] = 0;

                // 将修改结果保存到数据库
                mdlAccompany::instance()->updateQueue($queue[$num-1]["id"], ["next" => $queue[$num-1]["next"]]);
                mdlAccompany::instance()->updateQueue($queue[0]["id"], ["next" => $queue[0]["next"]]);
            }else{
                // 大于5个
                $queue[4]["next"] = $queue[0]["id"];
                $queue[0]["next"] = $queue[5]["id"];

                // 将修改结果保存到数据库
                mdlAccompany::instance()->updateQueue($queue[4]["id"], ["next" => $queue[4]["next"]]);
                mdlAccompany::instance()->updateQueue($queue[0]["id"], ["next" => $queue[0]["next"]]);
            }
// 修改完后，重新将数据更新到数据库中，然后重新排序即可
$queue = self::sort($queue);
```

> php 数组从 0 开始索引

可以看到，这个就如链表的插入操作类似。修改完成后，重新将数据更新到数据库中，然后重新排序即可。

如此，便实现了一个简单的数据库链表结构，当然，你也可以根据需求，实现双向链表之类，其他数据结构实现可以类比。
