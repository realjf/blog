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
今天遇到一个需求，在一个排队队列中，对第一个人员可以进行延后处理操作（实际是往后移动4位，到第5位），一开始想通过排序值
控制队列排序问题，但是容错性差，不能得到很好的效果，想来想去链表结构的特性对于插入删除O(1)的性能，可以很好的解决我的问题，
所以决定通过数据库表设计来实现一个链表。

- 数据库：mysql
- 程序语言：php

## 实现
表结构简化成只有id和next指针的设计，next指向下一个成员的id。最后一个成员的next指向0。

表结构及数值如下：
| id | next |
|:---:|:---:|
| 1 | 3 |
| 2 | 1 |
| 3 | 4 |
| 4 | 5 |
| 5 | 6 |
| 6 | 0 |

整理成链表大致是这样的
```text
2 --> 1 --> 3 --> 4 --> 5 --> 6 --> 0
```
最后的0代表链表结束。

按需求，如果第一个人员延后操作，需要向后移动4位，步骤是这样的：

首先将队列所有人员从数据库中取出，然后在程序中按照链表结构排序，排序程序如下
```php
static public function sort($queue)
{
        if (!$queue) {
            return $queue;
        }
        $callback = function ($a, $b) {
            // 如果a的下一个成员是b，则a<b
            if ($a["next"] == $b["id"]) {
                return -1;
            }
            // 如果a是队尾，则返回a>b
            if ($a["next"] == 0) {
                return 1;
            }
            // 如果b是队尾，则返回a<b
            if ($b["next"] == 0) {
                return -1;
            }
            // 如果b的下一个成员是a，则a>b
            if ($b["next"] == $a["id"]) {
                return 1;
            }
        };
        usort($queue, $callback);
        return $queue;
    }
```
排序完成后，需要对链表进行移动操作，把第一个人员移动到第5位，程序实现如下：
```php
// 将第5个的next修改为这个用户的id，然后把该用户的next修改为第6个用户的id
$queue[4]["next"] = $queue[0]["id"];
$queue[0]["next"] = $queue[5]["id"];

$queue = self::sort($queue);
```
> php数组从0开始索引

可以看到，这个就如链表的插入操作类似。修改完成后，重新排序即可。

如此，便实现了一个简单的数据库链表结构，当然，你也可以根据需求，实现双向链表之类，其他数据结构实现可以类比。

