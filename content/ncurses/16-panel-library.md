---
title: "NCURSES编程 之 16 平面库 16 Panel Library"
date: 2019-03-05T11:04:04+08:00
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

## 16 平面库
既然你精通curses，你就想做些大事。您创建了许多重叠的窗口，以提供专业的窗口类型外观。不幸的是，很快就很难管理这些。多次刷新、更新让你陷入噩梦。每当你忘记按正确的顺序刷新窗口时，重叠的窗口就会产生斑点。

不要绝望。panels库提供了一个优雅的解决方案。用网络课程开发者的话说

如果您的界面设计使得windows在运行时可能会深入可见性堆栈或弹出到顶层，那么所产生的簿记可能会很乏味，而且很难正确进行。因此，面板库。

如果你有很多重叠的窗口，那么面板库是一个不错的选择。它消除了执行一系列wnoutrefresh（）、doupdate（）的需要，并且减轻了正确执行的负担（自下而上）。该库维护有关窗口顺序、重叠和正确更新屏幕的信息。为什么要等？让我们仔细看一下面板。

### 16.1. 基础知识
面板对象是一个窗口，它被隐式地视为包含所有其他面板对象的面板的一部分。甲板被视为一个堆垛，顶部面板完全可见，其他面板根据其位置可能会或可能不会被遮挡。因此，基本思想是创建一个重叠面板的堆栈，并使用面板库来正确显示它们。有一个类似于refresh（）的函数，它在调用时按正确的顺序显示面板。提供隐藏或显示面板、移动面板、更改其大小等功能。在所有调用这些函数的过程中，重叠问题由panels库管理。

面板程序的一般流程如下：
- 创建要附加到面板的窗口（使用newwin（））。
- 使用选定的可见性顺序创建面板。根据需要的能见度把它们叠起来。函数new_panel（）用于创建面板。
- 调用update_panels（）将面板以正确的可见性顺序写入虚拟屏幕。执行doupdate（）以在屏幕上显示它。
- 用show_panel（）、hide_panel（）、move_panel（）等填充面板。使用panel_hidden（）和panel_window（）等辅助函数。使用用户指针存储面板的自定义数据。使用函数set_panel_userptr（）和panel_userptr（）设置并获取面板的用户指针。
- 完成面板操作后，请使用del_panel（）删除面板。

让我们用一些程序把概念弄清楚。下面是一个简单的程序，它创建了3个重叠面板并在屏幕上显示它们。

### 16.2. 使用面板库编译
要使用panels库函数，必须包含panel.h，并且要将程序与panels库链接起来，标志-lpanel应该按顺序与-lncurs一起添加。

```sh
#include <panel.h>
    .
    .
    .

    compile and link: gcc <program file> -lpanel -lncurses
```
示例：
```cpp
#include <panel.h>

int main()
{	WINDOW *my_wins[3];
	PANEL  *my_panels[3];
	int lines = 10, cols = 40, y = 2, x = 4, i;

	initscr();
	cbreak();
	noecho();

	/* Create windows for the panels */
	my_wins[0] = newwin(lines, cols, y, x);
	my_wins[1] = newwin(lines, cols, y + 1, x + 5);
	my_wins[2] = newwin(lines, cols, y + 2, x + 10);

	/*
	 * Create borders around the windows so that you can see the effect
	 * of panels
	 */
	for(i = 0; i < 3; ++i)
		box(my_wins[i], 0, 0);

	/* Attach a panel to each window */ 	/* Order is bottom up */
	my_panels[0] = new_panel(my_wins[0]); 	/* Push 0, order: stdscr-0 */
	my_panels[1] = new_panel(my_wins[1]); 	/* Push 1, order: stdscr-0-1 */
	my_panels[2] = new_panel(my_wins[2]); 	/* Push 2, order: stdscr-0-1-2 */

	/* Update the stacking order. 2nd panel will be on top */
	update_panels();

	/* Show it on the screen */
	doupdate();

	getch();
	endwin();
}
```
正如您所看到的，上面的程序遵循一个简单的流程，如所解释的那样。这些窗口是用newwin（）创建的，然后它们将附加到带有new_panel（）的面板上。当我们一个接一个的面板连接时，面板堆栈将被更新。要将它们放在屏幕上，请调用update炣panels（）和doupdate（）。

### 16.3. 面板窗口浏览
下面给出了一个稍微复杂的例子。此程序创建3个窗口，可以通过使用选项卡循环。看看代码。

```cpp
#include <panel.h>

#define NLINES 10
#define NCOLS 40

void init_wins(WINDOW **wins, int n);
void win_show(WINDOW *win, char *label, int label_color);
void print_in_middle(WINDOW *win, int starty, int startx, int width, char *string, chtype color);

int main()
{	WINDOW *my_wins[3];
	PANEL  *my_panels[3];
	PANEL  *top;
	int ch;

	/* Initialize curses */
	initscr();
	start_color();
	cbreak();
	noecho();
	keypad(stdscr, TRUE);

	/* Initialize all the colors */
	init_pair(1, COLOR_RED, COLOR_BLACK);
	init_pair(2, COLOR_GREEN, COLOR_BLACK);
	init_pair(3, COLOR_BLUE, COLOR_BLACK);
	init_pair(4, COLOR_CYAN, COLOR_BLACK);

	init_wins(my_wins, 3);

	/* Attach a panel to each window */ 	/* Order is bottom up */
	my_panels[0] = new_panel(my_wins[0]); 	/* Push 0, order: stdscr-0 */
	my_panels[1] = new_panel(my_wins[1]); 	/* Push 1, order: stdscr-0-1 */
	my_panels[2] = new_panel(my_wins[2]); 	/* Push 2, order: stdscr-0-1-2 */

	/* Set up the user pointers to the next panel */
	set_panel_userptr(my_panels[0], my_panels[1]);
	set_panel_userptr(my_panels[1], my_panels[2]);
	set_panel_userptr(my_panels[2], my_panels[0]);

	/* Update the stacking order. 2nd panel will be on top */
	update_panels();

	/* Show it on the screen */
	attron(COLOR_PAIR(4));
	mvprintw(LINES - 2, 0, "Use tab to browse through the windows (F1 to Exit)");
	attroff(COLOR_PAIR(4));
	doupdate();

	top = my_panels[2];
	while((ch = getch()) != KEY_F(1))
	{	switch(ch)
		{	case 9:
				top = (PANEL *)panel_userptr(top);
				top_panel(top);
				break;
		}
		update_panels();
		doupdate();
	}
	endwin();
	return 0;
}

/* Put all the windows */
void init_wins(WINDOW **wins, int n)
{	int x, y, i;
	char label[80];

	y = 2;
	x = 10;
	for(i = 0; i < n; ++i)
	{	wins[i] = newwin(NLINES, NCOLS, y, x);
		sprintf(label, "Window Number %d", i + 1);
		win_show(wins[i], label, i + 1);
		y += 3;
		x += 7;
	}
}

/* Show the window with a border and a label */
void win_show(WINDOW *win, char *label, int label_color)
{	int startx, starty, height, width;

	getbegyx(win, starty, startx);
	getmaxyx(win, height, width);

	box(win, 0, 0);
	mvwaddch(win, 2, 0, ACS_LTEE);
	mvwhline(win, 2, 1, ACS_HLINE, width - 2);
	mvwaddch(win, 2, width - 1, ACS_RTEE);

	print_in_middle(win, 1, 0, width, label, COLOR_PAIR(label_color));
}

void print_in_middle(WINDOW *win, int starty, int startx, int width, char *string, chtype color)
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
	wattron(win, color);
	mvwprintw(win, y, x, "%s", string);
	wattroff(win, color);
	refresh();
}
```
### 16.4. 使用用户指针
在上面的例子中，我使用了用户指针来找出循环中的下一个窗口。我们可以通过指定用户指针将自定义信息附加到面板，该指针可以指向您要存储的任何信息。在本例中，我存储了指向循环中下一个面板的指针。面板的用户指针可以通过函数set_panel_userptr（）设置。可以使用函数panel_userptr（）访问它，该函数将返回作为参数给定的面板的用户指针。在找到循环中的下一个面板后，函数top_panel（）将它带到顶部。此函数将作为参数提供的面板带到面板堆栈的顶部。

### 16.5. 移动和调整面板大小
函数move_panel（）可用于将面板移动到所需位置。它不会更改面板在堆栈中的位置。确保在与面板关联的窗口上使用move_panel（）而不是mvwin（）。
调整面板的大小有点复杂。没有直接的功能，只是调整与面板相关联的窗口的大小。调整面板大小的解决方案是创建具有所需大小的新窗口，使用replace_panel（）更改与面板关联的窗口。别忘了删除旧窗口。与面板相关联的窗口可以通过使用功能panel_window（）找到。

下面的程序用一个简单的程序展示了这些概念。您可以像往常一样使用<TAB>在窗口中循环。要调整或移动活动面板，请按“r”调整大小，按“m”移动。然后使用箭头键调整大小或将其移动到所需的方式，然后按enter键结束调整大小或移动。此示例使用用户数据来获取执行操作所需的数据。

```cpp
#include <panel.h>

typedef struct _PANEL_DATA {
	int x, y, w, h;
	char label[80];
	int label_color;
	PANEL *next;
}PANEL_DATA;

#define NLINES 10
#define NCOLS 40

void init_wins(WINDOW **wins, int n);
void win_show(WINDOW *win, char *label, int label_color);
void print_in_middle(WINDOW *win, int starty, int startx, int width, char *string, chtype color);
void set_user_ptrs(PANEL **panels, int n);

int main()
{	WINDOW *my_wins[3];
	PANEL  *my_panels[3];
	PANEL_DATA  *top;
	PANEL *stack_top;
	WINDOW *temp_win, *old_win;
	int ch;
	int newx, newy, neww, newh;
	int size = FALSE, move = FALSE;

	/* Initialize curses */
	initscr();
	start_color();
	cbreak();
	noecho();
	keypad(stdscr, TRUE);

	/* Initialize all the colors */
	init_pair(1, COLOR_RED, COLOR_BLACK);
	init_pair(2, COLOR_GREEN, COLOR_BLACK);
	init_pair(3, COLOR_BLUE, COLOR_BLACK);
	init_pair(4, COLOR_CYAN, COLOR_BLACK);

	init_wins(my_wins, 3);

	/* Attach a panel to each window */ 	/* Order is bottom up */
	my_panels[0] = new_panel(my_wins[0]); 	/* Push 0, order: stdscr-0 */
	my_panels[1] = new_panel(my_wins[1]); 	/* Push 1, order: stdscr-0-1 */
	my_panels[2] = new_panel(my_wins[2]); 	/* Push 2, order: stdscr-0-1-2 */

	set_user_ptrs(my_panels, 3);
	/* Update the stacking order. 2nd panel will be on top */
	update_panels();

	/* Show it on the screen */
	attron(COLOR_PAIR(4));
	mvprintw(LINES - 3, 0, "Use 'm' for moving, 'r' for resizing");
	mvprintw(LINES - 2, 0, "Use tab to browse through the windows (F1 to Exit)");
	attroff(COLOR_PAIR(4));
	doupdate();

	stack_top = my_panels[2];
	top = (PANEL_DATA *)panel_userptr(stack_top);
	newx = top->x;
	newy = top->y;
	neww = top->w;
	newh = top->h;
	while((ch = getch()) != KEY_F(1))
	{	switch(ch)
		{	case 9:		/* Tab */
				top = (PANEL_DATA *)panel_userptr(stack_top);
				top_panel(top->next);
				stack_top = top->next;
				top = (PANEL_DATA *)panel_userptr(stack_top);
				newx = top->x;
				newy = top->y;
				neww = top->w;
				newh = top->h;
				break;
			case 'r':	/* Re-Size*/
				size = TRUE;
				attron(COLOR_PAIR(4));
				mvprintw(LINES - 4, 0, "Entered Resizing :Use Arrow Keys to resize and press <ENTER> to end resizing");
				refresh();
				attroff(COLOR_PAIR(4));
				break;
			case 'm':	/* Move */
				attron(COLOR_PAIR(4));
				mvprintw(LINES - 4, 0, "Entered Moving: Use Arrow Keys to Move and press <ENTER> to end moving");
				refresh();
				attroff(COLOR_PAIR(4));
				move = TRUE;
				break;
			case KEY_LEFT:
				if(size == TRUE)
				{	--newx;
					++neww;
				}
				if(move == TRUE)
					--newx;
				break;
			case KEY_RIGHT:
				if(size == TRUE)
				{	++newx;
					--neww;
				}
				if(move == TRUE)
					++newx;
				break;
			case KEY_UP:
				if(size == TRUE)
				{	--newy;
					++newh;
				}
				if(move == TRUE)
					--newy;
				break;
			case KEY_DOWN:
				if(size == TRUE)
				{	++newy;
					--newh;
				}
				if(move == TRUE)
					++newy;
				break;
			case 10:	/* Enter */
				move(LINES - 4, 0);
				clrtoeol();
				refresh();
				if(size == TRUE)
				{	old_win = panel_window(stack_top);
					temp_win = newwin(newh, neww, newy, newx);
					replace_panel(stack_top, temp_win);
					win_show(temp_win, top->label, top->label_color);
					delwin(old_win);
					size = FALSE;
				}
				if(move == TRUE)
				{	move_panel(stack_top, newy, newx);
					move = FALSE;
				}
				break;

		}
		attron(COLOR_PAIR(4));
		mvprintw(LINES - 3, 0, "Use 'm' for moving, 'r' for resizing");
	    	mvprintw(LINES - 2, 0, "Use tab to browse through the windows (F1 to Exit)");
	    	attroff(COLOR_PAIR(4));
	        refresh();
		update_panels();
		doupdate();
	}
	endwin();
	return 0;
}

/* Put all the windows */
void init_wins(WINDOW **wins, int n)
{	int x, y, i;
	char label[80];

	y = 2;
	x = 10;
	for(i = 0; i < n; ++i)
	{	wins[i] = newwin(NLINES, NCOLS, y, x);
		sprintf(label, "Window Number %d", i + 1);
		win_show(wins[i], label, i + 1);
		y += 3;
		x += 7;
	}
}

/* Set the PANEL_DATA structures for individual panels */
void set_user_ptrs(PANEL **panels, int n)
{	PANEL_DATA *ptrs;
	WINDOW *win;
	int x, y, w, h, i;
	char temp[80];

	ptrs = (PANEL_DATA *)calloc(n, sizeof(PANEL_DATA));

	for(i = 0;i < n; ++i)
	{	win = panel_window(panels[i]);
		getbegyx(win, y, x);
		getmaxyx(win, h, w);
		ptrs[i].x = x;
		ptrs[i].y = y;
		ptrs[i].w = w;
		ptrs[i].h = h;
		sprintf(temp, "Window Number %d", i + 1);
		strcpy(ptrs[i].label, temp);
		ptrs[i].label_color = i + 1;
		if(i + 1 == n)
			ptrs[i].next = panels[0];
		else
			ptrs[i].next = panels[i + 1];
		set_panel_userptr(panels[i], &ptrs[i]);
	}
}

/* Show the window with a border and a label */
void win_show(WINDOW *win, char *label, int label_color)
{	int startx, starty, height, width;

	getbegyx(win, starty, startx);
	getmaxyx(win, height, width);

	box(win, 0, 0);
	mvwaddch(win, 2, 0, ACS_LTEE);
	mvwhline(win, 2, 1, ACS_HLINE, width - 2);
	mvwaddch(win, 2, width - 1, ACS_RTEE);

	print_in_middle(win, 1, 0, width, label, COLOR_PAIR(label_color));
}

void print_in_middle(WINDOW *win, int starty, int startx, int width, char *string, chtype color)
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
	wattron(win, color);
	mvwprintw(win, y, x, "%s", string);
	wattroff(win, color);
	refresh();
}
```
专注于主回路。一旦找到按下的键的类型，它就会采取适当的操作。如果按下“r”，则开始调整大小模式。之后，当用户按下箭头键时，新的尺寸将更新。当用户按下<ENTER>时，当前选择结束，并使用所解释的概念调整面板的大小。在调整大小模式下，程序不会显示窗口如何调整大小。当它被调整到一个新的位置时，打印一个虚线边框是留给读者的一个练习。
当用户按下“m”时，移动模式开始。这比调整大小要简单一些。当按下箭头键时，新位置将更新，按<ENTER>可通过调用函数move_panel（）移动面板。

在这个程序中，用户数据被表示为PANEL_DATA，在查找与面板相关的信息方面起着非常重要的作用。如注释中所述，PANEL_DATA存储面板大小、标签、标签颜色和指向循环中下一个面板的指针。

### 16.6. 隐藏和显示面板
可以使用函数hide_Panel（）隐藏面板。此函数只是将其从面板堆栈中移除，从而在update_panels（）和doupdate（）后将其隐藏在屏幕上。它不会破坏与隐藏面板关联的面板结构。可以使用show_panel（）函数再次显示。

下面的程序显示了面板的隐藏。按“a”或“b”或“c”分别显示或隐藏第一、第二和第三个窗口。它使用带有一个小变量hide的用户数据，该变量跟踪窗口是否被隐藏。出于某种原因，函数panel_hidden（）不起作用，该函数指示面板是否隐藏。Michael Andres也在这里提交了一份bug报告

```cpp
#include <panel.h>

typedef struct _PANEL_DATA {
	int hide;	/* TRUE if panel is hidden */
}PANEL_DATA;

#define NLINES 10
#define NCOLS 40

void init_wins(WINDOW **wins, int n);
void win_show(WINDOW *win, char *label, int label_color);
void print_in_middle(WINDOW *win, int starty, int startx, int width, char *string, chtype color);

int main()
{	WINDOW *my_wins[3];
	PANEL  *my_panels[3];
	PANEL_DATA panel_datas[3];
	PANEL_DATA *temp;
	int ch;

	/* Initialize curses */
	initscr();
	start_color();
	cbreak();
	noecho();
	keypad(stdscr, TRUE);

	/* Initialize all the colors */
	init_pair(1, COLOR_RED, COLOR_BLACK);
	init_pair(2, COLOR_GREEN, COLOR_BLACK);
	init_pair(3, COLOR_BLUE, COLOR_BLACK);
	init_pair(4, COLOR_CYAN, COLOR_BLACK);

	init_wins(my_wins, 3);

	/* Attach a panel to each window */ 	/* Order is bottom up */
	my_panels[0] = new_panel(my_wins[0]); 	/* Push 0, order: stdscr-0 */
	my_panels[1] = new_panel(my_wins[1]); 	/* Push 1, order: stdscr-0-1 */
	my_panels[2] = new_panel(my_wins[2]); 	/* Push 2, order: stdscr-0-1-2 */

	/* Initialize panel datas saying that nothing is hidden */
	panel_datas[0].hide = FALSE;
	panel_datas[1].hide = FALSE;
	panel_datas[2].hide = FALSE;

	set_panel_userptr(my_panels[0], &panel_datas[0]);
	set_panel_userptr(my_panels[1], &panel_datas[1]);
	set_panel_userptr(my_panels[2], &panel_datas[2]);

	/* Update the stacking order. 2nd panel will be on top */
	update_panels();

	/* Show it on the screen */
	attron(COLOR_PAIR(4));
	mvprintw(LINES - 3, 0, "Show or Hide a window with 'a'(first window)  'b'(Second Window)  'c'(Third Window)");
	mvprintw(LINES - 2, 0, "F1 to Exit");

	attroff(COLOR_PAIR(4));
	doupdate();

	while((ch = getch()) != KEY_F(1))
	{	switch(ch)
		{	case 'a':
				temp = (PANEL_DATA *)panel_userptr(my_panels[0]);
				if(temp->hide == FALSE)
				{	hide_panel(my_panels[0]);
					temp->hide = TRUE;
				}
				else
				{	show_panel(my_panels[0]);
					temp->hide = FALSE;
				}
				break;
			case 'b':
				temp = (PANEL_DATA *)panel_userptr(my_panels[1]);
				if(temp->hide == FALSE)
				{	hide_panel(my_panels[1]);
					temp->hide = TRUE;
				}
				else
				{	show_panel(my_panels[1]);
					temp->hide = FALSE;
				}
				break;
			case 'c':
				temp = (PANEL_DATA *)panel_userptr(my_panels[2]);
				if(temp->hide == FALSE)
				{	hide_panel(my_panels[2]);
					temp->hide = TRUE;
				}
				else
				{	show_panel(my_panels[2]);
					temp->hide = FALSE;
				}
				break;
		}
		update_panels();
		doupdate();
	}
	endwin();
	return 0;
}

/* Put all the windows */
void init_wins(WINDOW **wins, int n)
{	int x, y, i;
	char label[80];

	y = 2;
	x = 10;
	for(i = 0; i < n; ++i)
	{	wins[i] = newwin(NLINES, NCOLS, y, x);
		sprintf(label, "Window Number %d", i + 1);
		win_show(wins[i], label, i + 1);
		y += 3;
		x += 7;
	}
}

/* Show the window with a border and a label */
void win_show(WINDOW *win, char *label, int label_color)
{	int startx, starty, height, width;

	getbegyx(win, starty, startx);
	getmaxyx(win, height, width);

	box(win, 0, 0);
	mvwaddch(win, 2, 0, ACS_LTEE);
	mvwhline(win, 2, 1, ACS_HLINE, width - 2);
	mvwaddch(win, 2, width - 1, ACS_RTEE);

	print_in_middle(win, 1, 0, width, label, COLOR_PAIR(label_color));
}

void print_in_middle(WINDOW *win, int starty, int startx, int width, char *string, chtype color)
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
	wattron(win, color);
	mvwprintw(win, y, x, "%s", string);
	wattroff(win, color);
	refresh();
}
```

### 16.7. panel_above（）和panel_below（）函数
函数panel_above（）和panel_below（）可用于查找面板上方和下方的面板。如果这些函数的参数为NULL，则它们分别返回指向底部面板和顶部面板的指针。
