---
title: "NCURSES编程 之 20 Just for Fun"
date: 2021-03-05T16:22:04+08:00
keywords: ["ncurses"]
categories: ["ncurses"]
tags: ["ncurses"]
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

## 20 只是为了好玩！！！
这一节包含了我写的几个程序只是为了好玩。它们并不意味着更好的编程实践或使用ncurses的最佳方式。他们在这里提供，以便让初学者得到的想法，并添加更多的程序到这一节。如果你已经写了几个漂亮的，简单的诅咒程序，并希望他们包括在这里，联系我。

### 20.1. 生命的游戏
人生的游戏是数学的奇迹。用[保罗卡拉汉](http://www.math.com/students/wonders/life/life.html)的话说
生活的游戏（或简单的生活）不是传统意义上的游戏。在那里
没有球员，没有输赢。一旦“碎片”被放入
从一开始，规则决定了以后发生的一切。
然而，生活充满了惊喜！在大多数情况下，是不可能看的
在一个开始的位置（或模式），看看将来会发生什么。这个
唯一的办法就是遵守游戏规则。
这个节目从一个简单的倒U型开始，展示了生活的精彩。这个计划还有很大的改进空间。您可以让用户输入自己选择的模式，甚至可以从文件中获取输入。你也可以改变规则，玩很多变化。在谷歌上搜索有关生活游戏的有趣信息。
文件路径：JustForFun/life.c
### 20.2. 幻方
魔方，数学的另一个奇迹，很容易理解，但很难制作。在每行数字的幻方和中，每列相等。即使对角和也可以相等。有许多具有特殊性质的变体。
这个程序创建一个简单的奇数阶幻方。
文件路径：JustForFun/magic.c
### 20.3. 河內之塔
著名的河内塔。游戏的目的是将第一个销钉上的磁盘移动到最后一个销钉上，使用中间销钉作为临时停留。关键是在任何时候都不要把一个较大的磁盘放在一个较小的磁盘上。
文件路径：JustForFun/hanoi.c
### 20.4. 皇后拼图
著名的N皇后拼图的目的是把N个皇后放在一个nxn棋盘上而不互相攻击。
这个程序用一个简单的回溯技术来解决这个问题。
文件路径：JustForFun/queens.c
### 20.5. 洗牌
一个有趣的游戏，如果你有时间消磨的话。
文件路径：JustForFun/shuffle.c
### 20.6. 打字练习
一个简单的打字导师，我创造了更多的需要比方便使用。如果你知道如何正确地将手指放在键盘上，但缺乏练习，这会很有帮助。
文件路径：JustForFun/tt.c


## 参考文献
- [NCURSES Programming HOWTO](https://tldp.org/HOWTO/NCURSES-Programming-HOWTO/index.html)

- 下载地址[ftp://ftp.gnu.org/pub/gnu/ncurses/ncurses.tar.gz](ftp://ftp.gnu.org/pub/gnu/ncurses/ncurses.tar.gz)



