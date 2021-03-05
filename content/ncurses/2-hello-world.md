---
title: "NCURSES编程 之 2.Hell World 2 Hello World"
date: 2021-03-04T23:34:00+08:00
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

## 2 Hello World!!!
欢迎来到curses的世界。在我们深入到库中并研究它的各种特性之前，让我们编写一个简单的程序并向世界问好。

### 2.1 编译NCURSES库
要使用ncurses库函数，必须在程序中包含ncurses.h。要将程序与ncurses链接，应添加标志-lncurses。
```cpp
#include <ncurses.h>
    .
    .
    .

    compile and link: gcc <program file> -lncurses
```
例子1. Hello World!!!程序
```cpp
#include <ncurses.h>

int main()
{	
	initscr();			/* Start curses mode 		  */
	printw("Hello World !!!");	/* Print Hello World		  */
	refresh();			/* Print it on to the real screen */
	getch();			/* Wait for user input */
	endwin();			/* End curses mode		  */

	return 0;
}
```
### 2.2 解剖
上面的程序打印“你好，世界！！！”到屏幕和出口。这个程序显示如何初始化curses和做屏幕操作和结束curses模式。让我们一行一行地解剖它。

#### 2.2.1 关于initscr()
函数initscr（）在curses模式下初始化终端。在某些实现中，它清除屏幕并显示一个空白屏幕。要使用curses包进行任何屏幕操作，必须首先调用它。此函数初始化curses系统并为当前窗口（称为stdscr）和其他一些数据结构分配内存。在极端情况下，此函数可能会失败，因为内存不足，无法为curses库的数据结构分配内存。

完成之后，我们可以进行各种初始化来定制curses设置。这些细节将在后面解释。

#### 2.2.2 神秘的refresh()
下一行printw打印字符串“Hello World！！！”在屏幕上。此函数在所有方面都与普通printf类似，只是它在当前（y，x）坐标下打印名为stdscr的窗口上的数据。因为我们现在的坐标是0，0，所以字符串被打印在窗口的左角。

这就把我们带到了那个神秘的refresh()。嗯，当我们调用printw时，数据实际上被写入到一个虚构的窗口中，这个窗口在屏幕上还没有更新。printw的任务是更新一些标志和数据结构，并将数据写入与stdscr对应的缓冲区。为了在屏幕上显示它，我们需要调用refresh()并告诉curses系统在屏幕上转储内容。

这一切背后的理念是允许程序员在想象的屏幕或窗口上进行多次更新，并在完成所有屏幕更新后进行刷新。refresh()检查窗口并只更新已更改的部分。这提高了性能，也提供了更大的灵活性。但是，这对初学者来说有时是令人沮丧的。初学者犯的一个常见错误是在通过printw()类函数进行更新之后忘记调用refresh()。有时我还是忘了加上：-）

#### 2.2.3 关于endwin()
最后别忘了结束curses模式。否则，程序退出后，您的终端可能会出现异常行为。endwin()释放curses子系统及其数据结构占用的内存，并将终端置于正常模式。此函数必须在完成curses模式后调用。
