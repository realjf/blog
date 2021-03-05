---
title: "NCURSES编程 之 13. 屏幕操作 13 Screen Manipulation"
date: 2021-03-05T10:52:56+08:00
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

## 13 屏幕操作
在本节中，我们将研究一些函数，这些函数允许我们高效地管理屏幕并编写一些奇特的程序。这在编写游戏时尤其重要。

### 13.1. getyx（）函数
函数getyx（）可以用来找出当前光标的坐标。它将填充给定参数中的x和y坐标值。因为getyx（）是一个宏，所以不必传递变量的地址。它可以称为
```cpp
 getyx(win, y, x);
    /* win: window pointer
     *   y, x: y, x co-ordinates will be put into this variables 
     */
```
函数getparyx（）获取子窗口相对于主窗口的起始坐标。这有时对更新子窗口很有用。在设计诸如编写多个菜单之类的花哨东西时，很难存储菜单位置、它们的第一个选项坐标等。解决这个问题的一个简单方法是在子窗口中创建菜单，然后使用getparyx（）找到菜单的起始坐标。

函数getbegyx（）和getmaxyx（）存储当前窗口的起始坐标和最大坐标。这些函数在有效管理窗口和子窗口方面的作用与上述方法相同。

### 13.2. 屏幕转储
在编写游戏时，有时需要存储屏幕的状态并将其恢复到相同的状态。函数scr_dump（）可用于将屏幕内容转储到作为参数给定的文件中。以后可以通过scr_restore功能恢复。这两个简单的函数可以有效地用来维护一个快速移动的游戏和不断变化的场景。

### 13.3. 窗口转储
要存储和还原窗口，可以使用函数putwin（）和getwin（）。putwin（）将当前窗口状态放入一个文件中，稍后可以由getwin（）还原。

函数copywin（）可用于将一个窗口完全复制到另一个窗口上。它以源窗口和目标窗口为参数，根据指定的矩形，将矩形区域从源窗口复制到目标窗口。它的最后一个参数指定是覆盖还是只覆盖目标窗口上的内容。如果此参数为真，则复制是非破坏性的。


