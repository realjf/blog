---
title: "NCURSES编程 之 9.窗口 9 Windows"
date: 2019-03-05T10:11:03+08:00
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

## 9. 窗口
窗口是curses中最重要的概念。您已经看到了上面的标准窗口stdscr，其中所有函数都隐式地操作这个窗口。现在要使设计成为一个最简单的GUI，您需要借助windows。使用windows的主要原因可能是为了提高效率，通过只更新需要更改的窗口和更好的设计来分别操作部分屏幕。我想说，最后一个原因是最重要的，在去windows。你应该一直努力在你的程序中有一个更好的，易于管理的设计。如果您正在编写大型、复杂的gui，那么在开始做任何事情之前，这一点至关重要。

### 9.1. 基础知识
可以通过调用函数newwin（）来创建窗口。实际上，它不会在屏幕上产生任何东西。它为一个结构分配内存来操作窗口，并用有关窗口的数据（如大小、beginy、beginx等）更新结构。。因此，在curses中，窗口只是一个虚构窗口的抽象，可以独立于屏幕的其他部分进行操作。函数newwin（）返回指向结构窗口的指针，该指针可以传递给与窗口相关的函数，如wprintw（）等。。最后，可以使用delwin（）销毁窗口。它将释放与窗口结构关联的内存。

### 9.2. 让这里有一扇窗户！！！
如果创建了一个窗口而我们看不到它，那有什么好玩的呢。所以有趣的部分从展示窗口开始。函数box（）可用于在窗口周围绘制边框。让我们在本例中更详细地探讨这些函数。

例7。窗口边框示例
```cpp
#include <ncurses.h>


WINDOW *create_newwin(int height, int width, int starty, int startx);
void destroy_win(WINDOW *local_win);

int main(int argc, char *argv[])
{
  WINDOW *my_win;
	int startx, starty, width, height;
	int ch;

	initscr();			/* Start curses mode 		*/
	cbreak();			/* Line buffering disabled, Pass on
					 * everty thing to me 		*/
	keypad(stdscr, TRUE);		/* I need that nifty F1 	*/

	height = 3;
	width = 10;
	starty = (LINES - height) / 2;	/* Calculating for a center placement */
	startx = (COLS - width) / 2;	/* of the window		*/
	printw("Press F1 to exit");
	refresh();
	my_win = create_newwin(height, width, starty, startx);

	while((ch = getch()) != KEY_F(1))
	{	switch(ch)
		{	case KEY_LEFT:
				destroy_win(my_win);
				my_win = create_newwin(height, width, starty,--startx);
				break;
			case KEY_RIGHT:
				destroy_win(my_win);
				my_win = create_newwin(height, width, starty,++startx);
				break;
			case KEY_UP:
				destroy_win(my_win);
				my_win = create_newwin(height, width, --starty,startx);
				break;
			case KEY_DOWN:
				destroy_win(my_win);
				my_win = create_newwin(height, width, ++starty,startx);
				break;
		}
	}

	endwin();			/* End curses mode		  */
	return 0;
}

WINDOW *create_newwin(int height, int width, int starty, int startx)
{	WINDOW *local_win;

	local_win = newwin(height, width, starty, startx);
	box(local_win, 0 , 0);		/* 0, 0 gives default characters
					 * for the vertical and horizontal
					 * lines			*/
	wrefresh(local_win);		/* Show that box 		*/

	return local_win;
}

void destroy_win(WINDOW *local_win)
{
	/* box(local_win, ' ', ' '); : This won't produce the desired
	 * result of erasing the window. It will leave it's four corners
	 * and so an ugly remnant of window.
	 */
	wborder(local_win, ' ', ' ', ' ',' ',' ',' ',' ',' ');
	/* The parameters taken are
	 * 1. win: the window on which to operate
	 * 2. ls: character to be used for the left side of the window
	 * 3. rs: character to be used for the right side of the window
	 * 4. ts: character to be used for the top side of the window
	 * 5. bs: character to be used for the bottom side of the window
	 * 6. tl: character to be used for the top left corner of the window
	 * 7. tr: character to be used for the top right corner of the window
	 * 8. bl: character to be used for the bottom left corner of the window
	 * 9. br: character to be used for the bottom right corner of the window
	 */
	wrefresh(local_win);
	delwin(local_win);
}
```
### 9.3. 解释
别尖叫。我知道这是个很好的例子。但我必须在这里解释一些重要的事情：-）。这个程序创建一个矩形窗口，可以用左、右、上、下箭头键移动。它在用户按键时反复创建和销毁窗口。不要超出屏幕限制。检查这些限制留给读者作为练习。让我们一行一行地解剖它。

函数的作用是：用newwin（）创建一个窗口，并用box在窗口周围显示边框。函数destroy_win（）首先用“”字符绘制边框，然后调用delwin（）释放与其相关的内存，从而从屏幕中删除窗口。根据用户按下的键，starty或startx会被更改并创建一个新窗口。

如你所见，我用wborder代替了box。原因写在评论里（你错过了。我知道。阅读代码：-）。wborder在窗口周围绘制一个边框，其中指定的字符为4个角点和4条线。说得清楚一点，如果您按以下方式调用wborder：
```cpp
wborder(win, '|', '|', '-', '-', '+', '+', '+', '+');
```
它会产生类似
```cpp
    +------------+
    |            |
    |            |
    |            |
    |            |
    |            |
    |            |
    +------------+
```
### 9.4. 示例中的其他内容
您还可以在上面的示例中看到，我使用了变量COLS，这些行在initscr（）之后被初始化为屏幕大小。它们可用于查找屏幕尺寸和屏幕的中心坐标，如上所述。函数getch（）通常从键盘获取键，并根据键执行相应的工作。这种类型的开关盒在任何基于GUI的程序中都非常常见。

### 9.5. 其他边界功能
上面的程序是非常低效的，因为每次按下一个键，一个窗口被破坏，另一个窗口被创建。因此，让我们编写一个更有效的程序，使用其他与边界相关的函数。
下面的程序使用mvhline（）和mvvline（）来实现类似的效果。这两个函数很简单。它们在指定位置创建指定长度的水平或垂直线。

例8。更多边框功能
```cpp
#include <ncurses.h>

typedef struct _win_border_struct {
	chtype 	ls, rs, ts, bs,
	 	tl, tr, bl, br;
}WIN_BORDER;

typedef struct _WIN_struct {

	int startx, starty;
	int height, width;
	WIN_BORDER border;
}WIN;

void init_win_params(WIN *p_win);
void print_win_params(WIN *p_win);
void create_box(WIN *win, bool flag);

int main(int argc, char *argv[])
{	WIN win;
	int ch;

	initscr();			/* Start curses mode 		*/
	start_color();			/* Start the color functionality */
	cbreak();			/* Line buffering disabled, Pass on
					 * everty thing to me 		*/
	keypad(stdscr, TRUE);		/* I need that nifty F1 	*/
	noecho();
	init_pair(1, COLOR_CYAN, COLOR_BLACK);

	/* Initialize the window parameters */
	init_win_params(&win);
	print_win_params(&win);

	attron(COLOR_PAIR(1));
	printw("Press F1 to exit");
	refresh();
	attroff(COLOR_PAIR(1));

	create_box(&win, TRUE);
	while((ch = getch()) != KEY_F(1))
	{	switch(ch)
		{	case KEY_LEFT:
				create_box(&win, FALSE);
				--win.startx;
				create_box(&win, TRUE);
				break;
			case KEY_RIGHT:
				create_box(&win, FALSE);
				++win.startx;
				create_box(&win, TRUE);
				break;
			case KEY_UP:
				create_box(&win, FALSE);
				--win.starty;
				create_box(&win, TRUE);
				break;
			case KEY_DOWN:
				create_box(&win, FALSE);
				++win.starty;
				create_box(&win, TRUE);
				break;
		}
	}
	endwin();			/* End curses mode		  */
	return 0;
}
void init_win_params(WIN *p_win)
{
	p_win->height = 3;
	p_win->width = 10;
	p_win->starty = (LINES - p_win->height)/2;
	p_win->startx = (COLS - p_win->width)/2;

	p_win->border.ls = '|';
	p_win->border.rs = '|';
	p_win->border.ts = '-';
	p_win->border.bs = '-';
	p_win->border.tl = '+';
	p_win->border.tr = '+';
	p_win->border.bl = '+';
	p_win->border.br = '+';

}
void print_win_params(WIN *p_win)
{
#ifdef _DEBUG
	mvprintw(25, 0, "%d %d %d %d", p_win->startx, p_win->starty,
				p_win->width, p_win->height);
	refresh();
#endif
}
void create_box(WIN *p_win, bool flag)
{	int i, j;
	int x, y, w, h;

	x = p_win->startx;
	y = p_win->starty;
	w = p_win->width;
	h = p_win->height;

	if(flag == TRUE)
	{	mvaddch(y, x, p_win->border.tl);
		mvaddch(y, x + w, p_win->border.tr);
		mvaddch(y + h, x, p_win->border.bl);
		mvaddch(y + h, x + w, p_win->border.br);
		mvhline(y, x + 1, p_win->border.ts, w - 1);
		mvhline(y + h, x + 1, p_win->border.bs, w - 1);
		mvvline(y + 1, x, p_win->border.ls, h - 1);
		mvvline(y + 1, x + w, p_win->border.rs, h - 1);

	}
	else
		for(j = y; j <= y + h; ++j)
			for(i = x; i <= x + w; ++i)
				mvaddch(j, i, ' ');

	refresh();

}
```
