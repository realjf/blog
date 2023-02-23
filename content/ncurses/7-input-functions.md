---
title: "NCURSES编程 之 7.输入函数 7 Input Functions"
date: 2019-03-05T09:14:52+08:00
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

## 7. 输入函数
好吧，不用输入就打印，很无聊。让我们看看允许我们从用户那里获取输入的函数。这些功能也可以分为三类。
- getch（）类：获取字符
- scanw（）类：获取格式化输入
- getstr（）类：获取字符串

### 7.1. getch（）函数类
这些函数从终端读取单个字符。但有一些微妙的事实需要考虑。例如，如果不使用函数cbreak（），curses将不会连续读取输入字符，而是仅在遇到新行或EOF后才开始读取。为了避免这种情况，必须使用cbreak（）函数，以便程序可以立即使用字符。另一个广泛使用的函数是noecho（）。顾名思义，当设置（使用）这个函数时，用户输入的字符不会显示在屏幕上。两个函数cbreak（）和noecho（）是密钥管理的典型示例。这一类型的功能在密钥管理部分进行了说明。

### 7.2. scanw（）函数类
这些函数类似于scanf（），增加了从屏幕上任何位置获取输入的功能。

### 7.2.1. scanw（）和mvscanw
这些函数的用法类似于sscanf（），其中要扫描的行由wgetstr（）函数提供。也就是说，这些函数调用wgetstr（）函数（如下所述），并使用结果行进行扫描。

### 7.2.2. wscanw（）和mvwscanw（）
这些函数类似于上面的两个函数，只是它们从一个窗口中读取，该窗口作为这些函数的参数之一提供。

### 7.2.3. vwscanw（）
此函数类似于vscanf（）。当要扫描的参数数目可变时，可以使用此选项。

### 7.3. getstr（）函数类
这些函数用于从终端获取字符串。本质上，此函数执行的任务与对getch（）的一系列调用相同，直到收到换行符、回车符或文件结尾。结果字符串由str指向，str是用户提供的字符指针。

### 7.4. 一些例子
例4。一个简单的scanw示例
```cpp
#include <ncurses.h>			/* ncurses.h includes stdio.h */
#include <string.h>

int main()
{
 char mesg[]="Enter a string: ";		/* message to be appeared on the screen */
 char str[80];
 int row,col;				/* to store the number of rows and *
					 * the number of colums of the screen */
 initscr();				/* start the curses mode */
 getmaxyx(stdscr,row,col);		/* get the number of rows and columns */
 mvprintw(row/2,(col-strlen(mesg))/2,"%s",mesg);
                     		/* print the message at the center of the screen */
 getstr(str);
 mvprintw(LINES - 2, 0, "You Entered: %s", str);
 getch();
 endwin();

 return 0;
}
```
