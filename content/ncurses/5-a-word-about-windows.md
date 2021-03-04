---
title: "NCURSES编程 之 5.关于Windows的一句话 5 a Word About Windows"
date: 2021-03-05T00:07:39+08:00
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

## 5. 关于Windows的一句话

在我们深入讨论无数的ncurses函数之前，让我先澄清一下windows的一些问题。窗口将在以下[部分](https://tldp.org/HOWTO/NCURSES-Programming-HOWTO/windows.html)中详细说明

窗口是由curses系统定义的假想屏幕。窗口并不意味着通常在Win9X平台上看到的有边框的窗口。初始化curses时，它会创建一个名为stdscr的默认窗口，该窗口表示80x25（或正在运行的窗口的大小）屏幕。如果您正在执行一些简单的任务，如打印一些字符串、读取输入等，那么您可以安全地将此窗口用于所有目的。您还可以创建窗口并调用显式在指定窗口上工作的函数。

例如，如果你打调用
```cpp
printw("Hi There !!!");
refresh();
```
它在当前光标位置打印stdscr上的字符串。类似地，对refresh（）的调用仅适用于stdscr。
假设你已经创建了windows，那么你就必须调用一个在普通函数中加了w的函数。
```cpp
wprintw(win, "Hi There !!!");
wrefresh(win);
```
正如您将在文档的其余部分看到的，函数的命名遵循相同的约定。对于每个函数，通常还有三个以上的函数。
```cpp
    printw(string);        /* Print on stdscr at present cursor position */
    mvprintw(y, x, string);/* Move to (y, x) then print string     */
    wprintw(win, string);  /* Print on window win at present cursor position */
                           /* in the window */
    mvwprintw(win, y, x, string);   /* Move to (y, x) relative to window */
                                    /* co-ordinates and then print         */
```
无w函数通常是以stdscr作为窗口参数展开为相应w函数的宏。

