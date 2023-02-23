---
title: "NCURSES编程 之 10.颜色 10 Colors"
date: 2019-03-05T10:20:17+08:00
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

## 10. 颜色

### 10.1. 基础知识

没有色彩的生活似乎单调乏味。诅咒有一个很好的机制来处理颜色。让我们用一个小程序来深入了解这些事情。

```cpp
#include <ncurses.h>

void print_in_middle(WINDOW *win, int starty, int startx, int width, char *string);
int main(int argc, char *argv[])
{	initscr();			/* Start curses mode 		*/
	if(has_colors() == FALSE)
	{	endwin();
		printf("Your terminal does not support color\n");
		exit(1);
	}
	start_color();			/* Start color 			*/
	init_pair(1, COLOR_RED, COLOR_BLACK);

	attron(COLOR_PAIR(1));
	print_in_middle(stdscr, LINES / 2, 0, 0, "Viola !!! In color ...");
	attroff(COLOR_PAIR(1));
    	getch();
	endwin();
}
void print_in_middle(WINDOW *win, int starty, int startx, int width, char *string)
{	int length, x, y;
	float temp;

	if(win == NULL)
		win = stdscr;
	getyx(win, y, x);
	if(startx != 0)
		x = startx;
	if(starty != 0)
		y = starty;
	if(width == 0)
		width = 80;

	length = strlen(string);
	temp = (width - length)/ 2;
	x = startx + (int)temp;
	mvwprintw(win, y, x, "%s", string);
	refresh();
}
```
如您所见，要开始使用color，应该首先调用函数start_color（）。之后，您可以使用各种功能使用终端的颜色功能。若要确定终端是否具有颜色功能，可以使用has_colors（）函数，如果终端不支持颜色，该函数将返回FALSE。

当调用start_color（）时，Curses初始化终端支持的所有颜色。这些可以通过define常量来访问，比如COLOR_BLACK等。现在要真正开始使用颜色，必须定义颜色对。颜色总是成对使用。这意味着您必须使用函数init_pair（）为给定的配对号定义前景和背景。之后，可以使用COLOR_PAIR()函数将该对编号用作普通属性。一开始这似乎很麻烦。但这种优雅的解决方案使我们能够非常轻松地管理颜色对。要理解它，您必须查看“dialog”的源代码，dialog是一个用于从shell脚本显示对话框的实用程序。开发人员已经为他们可能需要的所有颜色定义了前景和背景组合，并在开始时进行了初始化。这使得通过访问一个我们已经定义为常量的对来设置属性变得非常容易。

以下颜色是在curses.h中定义的。您可以将它们用作各种颜色函数的参数。
```text
        COLOR_BLACK   0
        COLOR_RED     1
        COLOR_GREEN   2
        COLOR_YELLOW  3
        COLOR_BLUE    4
        COLOR_MAGENTA 5
        COLOR_CYAN    6
        COLOR_WHITE   7
```

### 10.2. 更改颜色定义
函数init_color（）可用于更改最初由curses定义的颜色的rgb值。假设你想把红色的强度减轻一点点。然后你可以用这个函数

```cpp
init_color(COLOR_RED, 700, 0, 0);
    /* param 1     : color name
     * param 2, 3, 4 : rgb content min = 0, max = 1000 */
```
如果终端无法更改颜色定义，则函数返回ERR。函数can_change_color（）可用于确定终端是否具有更改颜色内容的功能。rgb内容从0缩放到1000。最初，红色的定义为含量1000（r）、0（g）、0（b）。

### 10.3. 颜色含量
函数color_content（）和pair_content（）可用于查找颜色内容和该对的前景、背景组合。

