---
title: "NCURSES编程 之 4.初始化 4 Initialization"
date: 2019-03-04T23:49:20+08:00
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

## 4. 初始化
我们现在知道，要初始化curses系统，必须调用initscr（）函数。在初始化之后可以调用一些函数来定制curses会话。我们可以要求curses系统将终端设置为原始模式或初始化颜色或初始化鼠标等。。让我们来讨论一些通常在initscr（）之后立即调用的函数；

### 4.1. 初始化函数
### 4.2. raw（）和cbreak（）
通常，终端驱动程序缓冲用户键入的字符，直到遇到新行或回车符。但是大多数程序要求用户一输入字符就可以使用。以上两个函数用于禁用行缓冲。这两个函数之间的区别在于将suspend（CTRL-Z）、interrupt和quit（CTRL-C）等控制字符传递给程序的方式。在raw（）模式下，这些字符直接传递给程序而不生成信号。在cbreak（）模式下，终端驱动程序将这些控制字符解释为任何其他字符。我个人更喜欢使用raw（），因为我可以更好地控制用户的行为。

### 4.3. echo（）和noecho（）
这些函数控制用户键入的字符回显到终端。noecho（）关闭回声。这样做的原因可能是为了更好地控制回音，或者在通过getch（）等函数获取用户的输入时抑制不必要的回音。大多数交互式程序在初始化时调用noecho（），并以可控的方式进行字符回音。它使程序员能够灵活地在窗口的任何位置回显字符，而无需更新当前（y，x）坐标。

### 4.4. keypad（）
这是我最喜欢的初始化函数。它可以读取功能键，如F1、F2、箭头键等。几乎每个交互式程序都可以这样做，因为箭头键是任何用户界面的主要部分。设置 keypad（stdscr，TRUE）为常规屏幕（stdscr）启用此功能。您将在本文档后面的部分了解有关密钥管理的更多信息。

### 4.5. halfdelay（）
这个函数虽然不经常使用，但有时还是很有用的。调用halfdelay（）以启用半延迟模式，这与cbreak（）模式类似，因为键入的字符可立即用于程序。但是，如果没有可用的输入，它会等待十分之一秒的“X”输入，然后返回ERR，X'是传递给函数halfdelay（）的超时值。当您想请求用户输入时，此函数非常有用，如果用户在某个时间内没有响应，我们可以执行其他操作。一个可能的例子是密码提示超时。

### 4.6. 其他初始化函数
初始化时调用的函数很少，可以自定义curses行为。它们没有像上面提到的那样广泛使用。在适当的地方对其中的一些问题进行了解释。

### 4.7. 一个例子
让我们写一个程序来阐明这些函数的用法。

例2。初始化函数用法示例
```cpp
#include <ncurses.h>

int main()
{
  int ch;

	initscr();			/* Start curses mode 		*/
	raw();				/* Line buffering disabled	*/
	keypad(stdscr, TRUE);		/* We get F1, F2 etc..		*/
	noecho();			/* Don't echo() while we do getch */

    	printw("Type any character to see it in bold\n");
	ch = getch();			/* If raw() hadn't been called
					 * we have to press enter before it
					 * gets to the program 		*/
	if(ch == KEY_F(1))		/* Without keypad enabled this will */
		printw("F1 Key pressed");/*  not get to us either	*/
					/* Without noecho() some ugly escape
					 * charachters might have been printed
					 * on screen			*/
	else
	{	printw("The pressed key is ");
		attron(A_BOLD);
		printw("%c", ch);
		attroff(A_BOLD);
	}
	refresh();			/* Print it on to the real screen */
    	getch();			/* Wait for user input */
	endwin();			/* End curses mode		  */

	return 0;
}
```

这个程序是不言自明的。但我使用的函数还没有解释。函数getch（）用于从用户获取字符。它相当于普通的getchar（），只是我们可以禁用行缓冲以避免在输入之后<enter>。有关getch（）和读取密钥的更多信息，请参阅[密钥管理](https://tldp.org/HOWTO/NCURSES-Programming-HOWTO/keys.html)部分。函数attron和attroff分别用于打开和关闭某些属性。在这个例子中，我用它们以粗体打印字符。这些功能将在后面详细说明。
