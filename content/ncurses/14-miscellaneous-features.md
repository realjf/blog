---
title: "NCURSES编程 之 14 其他特性 14 Miscellaneous Features"
date: 2021-03-05T10:56:49+08:00
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

## 14 其他特性
现在你知道了足够的功能来编写一个好的诅咒程序，所有的钟和口哨。有一些在各种情况下有用的杂项函数。让我们直奔其中一些。

### 14.1. 光标集（）
此函数可用于使光标不可见。此函数的参数应为
```
 0 : invisible      or
    1 : normal    or
    2 : very visible.
```
### 14.2. 暂时离开curses模式
有时您可能想暂时回到熟食模式（正常行缓冲模式）。在这种情况下，首先需要通过调用def_prog_mode（）保存tty模式，然后调用endwin（）结束curses模式。这将使您处于原来的tty模式。完成后，要返回到curses，请调用reset_prog_mode（）。此函数用于将tty返回到def_prog_mode（）存储的状态。然后执行refresh（），您将返回到诅咒模式。下面是一个例子，展示了要做的事情的顺序。

例12。暂时离开诅咒模式
```cpp
#include <ncurses.h>

int main()
{	
	initscr();			/* Start curses mode 		  */
	printw("Hello World !!!\n");	/* Print Hello World		  */
	refresh();			/* Print it on to the real screen */
	def_prog_mode();		/* Save the tty modes		  */
	endwin();			/* End curses mode temporarily	  */
	system("/bin/sh");		/* Do whatever you like in cooked mode */
	reset_prog_mode();		/* Return to the previous tty mode*/
					/* stored by def_prog_mode() 	  */
	refresh();			/* Do refresh() to restore the	  */
					/* Screen contents		  */
	printw("Another String\n");	/* Back to curses use the full    */
	refresh();			/* capabilities of curses	  */
	endwin();			/* End curses mode		  */

	return 0;
}
```
### 14.3. ACS变量
如果你曾经在DOS下编程，你就会知道扩展字符集中那些漂亮的字符。它们只能在某些终端上打印。像box（）这样的NCURSES函数使用这些字符。所有这些变量都以ACS开头，表示可选字符集。你可能注意到我在上面的一些程序中使用了这些字符。下面是一个显示所有字符的示例。

例13。ACS变量示例
```cpp
#include <ncurses.h>

int main()
{
        initscr();

        printw("Upper left corner           "); addch(ACS_ULCORNER); printw("\n"); 
        printw("Lower left corner           "); addch(ACS_LLCORNER); printw("\n");
        printw("Lower right corner          "); addch(ACS_LRCORNER); printw("\n");
        printw("Tee pointing right          "); addch(ACS_LTEE); printw("\n");
        printw("Tee pointing left           "); addch(ACS_RTEE); printw("\n");
        printw("Tee pointing up             "); addch(ACS_BTEE); printw("\n");
        printw("Tee pointing down           "); addch(ACS_TTEE); printw("\n");
        printw("Horizontal line             "); addch(ACS_HLINE); printw("\n");
        printw("Vertical line               "); addch(ACS_VLINE); printw("\n");
        printw("Large Plus or cross over    "); addch(ACS_PLUS); printw("\n");
        printw("Scan Line 1                 "); addch(ACS_S1); printw("\n");
        printw("Scan Line 3                 "); addch(ACS_S3); printw("\n");
        printw("Scan Line 7                 "); addch(ACS_S7); printw("\n");
        printw("Scan Line 9                 "); addch(ACS_S9); printw("\n");
        printw("Diamond                     "); addch(ACS_DIAMOND); printw("\n");
        printw("Checker board (stipple)     "); addch(ACS_CKBOARD); printw("\n");
        printw("Degree Symbol               "); addch(ACS_DEGREE); printw("\n");
        printw("Plus/Minus Symbol           "); addch(ACS_PLMINUS); printw("\n");
        printw("Bullet                      "); addch(ACS_BULLET); printw("\n");
        printw("Arrow Pointing Left         "); addch(ACS_LARROW); printw("\n");
        printw("Arrow Pointing Right        "); addch(ACS_RARROW); printw("\n");
        printw("Arrow Pointing Down         "); addch(ACS_DARROW); printw("\n");
        printw("Arrow Pointing Up           "); addch(ACS_UARROW); printw("\n");
        printw("Board of squares            "); addch(ACS_BOARD); printw("\n");
        printw("Lantern Symbol              "); addch(ACS_LANTERN); printw("\n");
        printw("Solid Square Block          "); addch(ACS_BLOCK); printw("\n");
        printw("Less/Equal sign             "); addch(ACS_LEQUAL); printw("\n");
        printw("Greater/Equal sign          "); addch(ACS_GEQUAL); printw("\n");
        printw("Pi                          "); addch(ACS_PI); printw("\n");
        printw("Not equal                   "); addch(ACS_NEQUAL); printw("\n");
        printw("UK pound sign               "); addch(ACS_STERLING); printw("\n");

        refresh();
        getch();
        endwin();

	return 0;
}

```
