---
title: "NCURSES编程 之 17.菜单库 17 Menus Library"
date: 2019-03-05T14:35:25+08:00
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

## 17 菜单库
菜单库提供了基本curses的一个很好的扩展，通过它可以创建菜单。它提供了一组创建菜单的函数。但是，他们必须定制，以提供更好的外观，颜色等。让我们进入细节。

菜单是一个屏幕显示，它帮助用户选择给定项目集的某些子集。简单地说，菜单是一个项目集合，其中一个或多个项目可以从中选择。有些读者可能不知道多个项目选择功能。菜单库提供了编写菜单的功能，用户可以从中选择多个项目作为首选选项。这将在后面的一节中讨论。现在是时候开始做一些基础知识了。

### 17.1。基础知识
要创建菜单，首先创建项目，然后将菜单张贴到显示。之后，所有用户响应的处理都是在优雅的函数menu_driver（）中完成的，该菜单是任何菜单程序的工作马。

菜单程序的控制流程如下所示。

- 初始化curses
- 使用new炣item（）创建项目。可以为项目指定名称和说明。
- 通过指定要附加的项，使用new_menu（）创建菜单。
- 使用menu_Post（）发布”菜单，然后刷新屏幕。
- 使用循环处理用户请求，并使用菜单“驱动程序”对菜单进行必要的更新。
- 用menu_Unpost（）取消对菜单的选中”
- 释放由free_menu（）分配给菜单的内存
- 释放分配给项目的内存（使用free_item（）
- 结束curses

让我们看看一个程序，它打印一个简单的菜单，并用上下箭头更新当前选择。

### 17.2. 使用菜单库编译
要使用菜单库函数，您必须包括menu.h，并且要将程序与菜单库链接，则应按此顺序添加标记-lmenu和-lncurs。
```
#include <menu.h>
    .
    .
    .

    compile and link: gcc <program file> -lmenu -lncurses
```
菜单基础
```cpp
#include <curses.h>
#include <menu.h>

#define ARRAY_SIZE(a) (sizeof(a) / sizeof(a[0]))
#define CTRLD 	4

char *choices[] = {
                        "Choice 1",
                        "Choice 2",
                        "Choice 3",
                        "Choice 4",
                        "Exit",
                  };

int main()
{	ITEM **my_items;
	int c;
	MENU *my_menu;
	int n_choices, i;
	ITEM *cur_item;


	initscr();
	cbreak();
	noecho();
	keypad(stdscr, TRUE);

	n_choices = ARRAY_SIZE(choices);
	my_items = (ITEM **)calloc(n_choices + 1, sizeof(ITEM *));

	for(i = 0; i < n_choices; ++i)
	        my_items[i] = new_item(choices[i], choices[i]);
	my_items[n_choices] = (ITEM *)NULL;

	my_menu = new_menu((ITEM **)my_items);
	mvprintw(LINES - 2, 0, "F1 to Exit");
	post_menu(my_menu);
	refresh();

	while((c = getch()) != KEY_F(1))
	{   switch(c)
	    {	case KEY_DOWN:
		        menu_driver(my_menu, REQ_DOWN_ITEM);
				break;
			case KEY_UP:
				menu_driver(my_menu, REQ_UP_ITEM);
				break;
		}
	}

	free_item(my_items[0]);
	free_item(my_items[1]);
	free_menu(my_menu);
	endwin();
}
```
此程序演示了使用菜单库创建菜单所涉及的基本概念。首先，我们使用new_item（）创建项目，然后使用new_menu（）函数将它们附加到菜单中。在张贴菜单并刷新屏幕后，主处理循环开始。它读取用户输入并采取相应的操作。函数menu_driver（）是菜单系统的主要工作马。此函数的第二个参数告诉您要对菜单执行什么操作。根据参数,menu_driver（）执行相应的任务。该值可以是菜单导航请求、ascii字符或与鼠标事件关联的KEY_MOUSE专用键。

menu_driver接受以下导航请求。
```text
     REQ_LEFT_ITEM         Move left to an item.
     REQ_RIGHT_ITEM      Move right to an item.
     REQ_UP_ITEM         Move up to an item.
     REQ_DOWN_ITEM       Move down to an item.
     REQ_SCR_ULINE       Scroll up a line.
     REQ_SCR_DLINE          Scroll down a line.
     REQ_SCR_DPAGE          Scroll down a page.
     REQ_SCR_UPAGE         Scroll up a page.
     REQ_FIRST_ITEM     Move to the first item.
     REQ_LAST_ITEM         Move to the last item.
     REQ_NEXT_ITEM         Move to the next item.
     REQ_PREV_ITEM         Move to the previous item.
     REQ_TOGGLE_ITEM     Select/deselect an item.
     REQ_CLEAR_PATTERN     Clear the menu pattern buffer.
     REQ_BACK_PATTERN      Delete the previous character from the pattern buffer.
     REQ_NEXT_MATCH     Move to the next item matching the pattern match.
     REQ_PREV_MATCH     Move to the previous item matching the pattern match.
```
别被这么多选择弄得不知所措。我们将一个接一个地慢慢地看到他们。本例中感兴趣的选项是REQ_UP_ITEM和REQ_DOWN_ITEM。这两个选项传递给菜单驱动程序时，菜单驱动程序将分别向上或向下更新当前项。

### 17.3. 菜单驱动程序：菜单系统的工作马
正如您在上面的示例中所看到的，菜单驱动程序在更新菜单中起着重要的作用。这是非常重要的，了解各种选择，它需要和他们做什么。如上所述，menu_driver（）的第二个参数可以是导航请求、可打印字符或KEY_MOUSE 键。让我们分析一下不同的导航请求。

- REQ_LEFT_ITEM 和REQ_RIGHT_ITEM
一个菜单可以为多个项目显示多个列。这可以通过使用menu_format（）函数来完成。当显示多列菜单时，这些请求会导致菜单驱动程序将当前选择向左或向右移动。
- REQ_UP_ITEM 和REQ_DOWN_ITEM
您在上面的示例中看到了这两个选项。这些选项在给定时，使菜单驱动程序向上或向下移动当前选择项。
- REQ_SCR_*选项
四个选项REQ_SCR_ULINE、REQ_SCR_DLINE、REQ_SCR_DPAGE、REQ_SCR_UPAGE 与滚动相关。如果菜单子窗口中无法显示菜单中的所有项目，则菜单可滚动。可以将这些请求提供给menu_driver ，以便分别向上、向下或向下或向上滚动一行。

- REQ_FIRST_ITEM、REQ_LAST_ITEM、REQ_NEXT_ITEM 和REQ_PREV_ITEM
这些要求不言自明。
- REQ_TOGGLE_ITEM
给出此请求时，切换当前选择。此选项仅在多值菜单中使用。因此，要使用此请求，必须禁用选项O_ONEVALUE 。此选项可通过set_menu_opts（）关闭或打开。
- 模式请求
每个菜单都有一个关联的模式缓冲区，用于查找与用户输入的ascii字符最接近的匹配项。每当ascii字符被赋予menu_driver时，它就会放入模式缓冲区。它还尝试在项目列表中查找与模式最接近的匹配项，并将当前选择移动到该项目。请求REQ_CLEAR_PATTERN 清除模式缓冲区。请求 REQ_BACK_PATTERN 删除模式缓冲区中的前一个字符。如果模式匹配多个项目，那么匹配的项目可以通过REQ_NEXT_MATCH 和REQ_PREV_MATCH 循环，REQ_NEXT_MATCH 和REQ_PREV_MATCH 分别将当前选择移动到下一个和上一个匹配。
- 鼠标请求

在按键鼠标请求的情况下，根据鼠标位置采取相应的操作。手册页中解释了要采取的措施：，
```
If  the  second argument is the KEY_MOUSE special key, the
       associated mouse event is translated into one of the above
       pre-defined  requests.   Currently only clicks in the user
       window (e.g. inside the menu display area or  the  decora­
       tion  window)  are handled. If you click above the display
       region of the menu, a REQ_SCR_ULINE is generated,  if  you
       doubleclick  a  REQ_SCR_UPAGE  is  generated  and  if  you
       tripleclick a REQ_FIRST_ITEM is generated.  If  you  click
       below  the  display region of the menu, a REQ_SCR_DLINE is
       generated, if you doubleclick a REQ_SCR_DPAGE is generated
       and  if  you  tripleclick a REQ_LAST_ITEM is generated. If
       you click at an item inside the display area of the  menu,
       the menu cursor is positioned to that item.
```
以上每一项请求都将在以下几行中解释，并在适当的时候举例说明。

### 17.4. 菜单窗口
创建的每个菜单都与一个窗口和一个子窗口相关联。菜单窗口显示与菜单关联的任何标题或边框。菜单子窗口显示当前可供选择的菜单项。但在这个简单的示例中，我们没有指定任何窗口或子窗口。如果没有指定窗口，则将stdscr作为主窗口，然后菜单系统计算显示项目所需的子窗口大小。然后项目将显示在计算子窗口中。所以让我们玩这些窗口，并显示一个带有边框和标题的菜单。

例19。菜单窗口使用示例

```cpp
#include <menu.h>

#define ARRAY_SIZE(a) (sizeof(a) / sizeof(a[0]))
#define CTRLD 	4

char *choices[] = {
                        "Choice 1",
                        "Choice 2",
                        "Choice 3",
                        "Choice 4",
                        "Exit",
                        (char *)NULL,
                  };
void print_in_middle(WINDOW *win, int starty, int startx, int width, char *string, chtype color);

int main()
{	ITEM **my_items;
	int c;
	MENU *my_menu;
        WINDOW *my_menu_win;
        int n_choices, i;

	/* Initialize curses */
	initscr();
	start_color();
        cbreak();
        noecho();
	keypad(stdscr, TRUE);
	init_pair(1, COLOR_RED, COLOR_BLACK);

	/* Create items */
        n_choices = ARRAY_SIZE(choices);
        my_items = (ITEM **)calloc(n_choices, sizeof(ITEM *));
        for(i = 0; i < n_choices; ++i)
                my_items[i] = new_item(choices[i], choices[i]);

	/* Crate menu */
	my_menu = new_menu((ITEM **)my_items);

	/* Create the window to be associated with the menu */
        my_menu_win = newwin(10, 40, 4, 4);
        keypad(my_menu_win, TRUE);

	/* Set main window and sub window */
        set_menu_win(my_menu, my_menu_win);
        set_menu_sub(my_menu, derwin(my_menu_win, 6, 38, 3, 1));

	/* Set menu mark to the string " * " */
        set_menu_mark(my_menu, " * ");

	/* Print a border around the main window and print a title */
        box(my_menu_win, 0, 0);
	print_in_middle(my_menu_win, 1, 0, 40, "My Menu", COLOR_PAIR(1));
	mvwaddch(my_menu_win, 2, 0, ACS_LTEE);
	mvwhline(my_menu_win, 2, 1, ACS_HLINE, 38);
	mvwaddch(my_menu_win, 2, 39, ACS_RTEE);
	mvprintw(LINES - 2, 0, "F1 to exit");
	refresh();

	/* Post the menu */
	post_menu(my_menu);
	wrefresh(my_menu_win);

	while((c = wgetch(my_menu_win)) != KEY_F(1))
	{       switch(c)
	        {	case KEY_DOWN:
				menu_driver(my_menu, REQ_DOWN_ITEM);
				break;
			case KEY_UP:
				menu_driver(my_menu, REQ_UP_ITEM);
				break;
		}
                wrefresh(my_menu_win);
	}

	/* Unpost and free all the memory taken up */
        unpost_menu(my_menu);
        free_menu(my_menu);
        for(i = 0; i < n_choices; ++i)
                free_item(my_items[i]);
	endwin();
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
本示例创建一个菜单，其中包含标题、边框、分隔标题和项目的花哨行。如您所见，为了将窗口附加到菜单，必须使用函数set_menu_win（）。然后我们还附加了子窗口。这将显示子窗口中的项目。您还可以设置标记字符串，该字符串将显示在所选项目的左侧，并设置为set_menu_mark（）。

### 17.5. 滚动菜单
如果为窗口指定的子窗口不够大，无法显示所有项目，则该菜单将可滚动。当您处于当前列表中的最后一个项目时，如果您将REQ_DOWN_ITEM发送，则它将转换为REQ_SCR_DLINE，菜单按一个项目滚动。您可以手动执行REQ_SCR_ 操作来执行滚动。让我们看看怎么做。
```cpp
#include <curses.h>
#include <menu.h>

#define ARRAY_SIZE(a) (sizeof(a) / sizeof(a[0]))
#define CTRLD 	4

char *choices[] = {
                        "Choice 1",
                        "Choice 2",
                        "Choice 3",
                        "Choice 4",
			"Choice 5",
			"Choice 6",
			"Choice 7",
			"Choice 8",
			"Choice 9",
			"Choice 10",
                        "Exit",
                        (char *)NULL,
                  };
void print_in_middle(WINDOW *win, int starty, int startx, int width, char *string, chtype color);

int main()
{	ITEM **my_items;
	int c;
	MENU *my_menu;
        WINDOW *my_menu_win;
        int n_choices, i;

	/* Initialize curses */
	initscr();
	start_color();
        cbreak();
        noecho();
	keypad(stdscr, TRUE);
	init_pair(1, COLOR_RED, COLOR_BLACK);
	init_pair(2, COLOR_CYAN, COLOR_BLACK);

	/* Create items */
        n_choices = ARRAY_SIZE(choices);
        my_items = (ITEM **)calloc(n_choices, sizeof(ITEM *));
        for(i = 0; i < n_choices; ++i)
                my_items[i] = new_item(choices[i], choices[i]);

	/* Crate menu */
	my_menu = new_menu((ITEM **)my_items);

	/* Create the window to be associated with the menu */
        my_menu_win = newwin(10, 40, 4, 4);
        keypad(my_menu_win, TRUE);

	/* Set main window and sub window */
        set_menu_win(my_menu, my_menu_win);
        set_menu_sub(my_menu, derwin(my_menu_win, 6, 38, 3, 1));
	set_menu_format(my_menu, 5, 1);

	/* Set menu mark to the string " * " */
        set_menu_mark(my_menu, " * ");

	/* Print a border around the main window and print a title */
        box(my_menu_win, 0, 0);
	print_in_middle(my_menu_win, 1, 0, 40, "My Menu", COLOR_PAIR(1));
	mvwaddch(my_menu_win, 2, 0, ACS_LTEE);
	mvwhline(my_menu_win, 2, 1, ACS_HLINE, 38);
	mvwaddch(my_menu_win, 2, 39, ACS_RTEE);

	/* Post the menu */
	post_menu(my_menu);
	wrefresh(my_menu_win);

	attron(COLOR_PAIR(2));
	mvprintw(LINES - 2, 0, "Use PageUp and PageDown to scoll down or up a page of items");
	mvprintw(LINES - 1, 0, "Arrow Keys to navigate (F1 to Exit)");
	attroff(COLOR_PAIR(2));
	refresh();

	while((c = wgetch(my_menu_win)) != KEY_F(1))
	{       switch(c)
	        {	case KEY_DOWN:
				menu_driver(my_menu, REQ_DOWN_ITEM);
				break;
			case KEY_UP:
				menu_driver(my_menu, REQ_UP_ITEM);
				break;
			case KEY_NPAGE:
				menu_driver(my_menu, REQ_SCR_DPAGE);
				break;
			case KEY_PPAGE:
				menu_driver(my_menu, REQ_SCR_UPAGE);
				break;
		}
                wrefresh(my_menu_win);
	}

	/* Unpost and free all the memory taken up */
        unpost_menu(my_menu);
        free_menu(my_menu);
        for(i = 0; i < n_choices; ++i)
                free_item(my_items[i]);
	endwin();
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
这个程序是不言自明的。在这个例子中，选择的数量增加到了10个，这比我们的子窗口大，子窗口可以容纳6个项目。必须使用功能set_menu_format（）将此消息显式传送到菜单系统。在这里，我们指定要为单个页面显示的行数和列数。我们可以在rows变量中指定要显示的任意数量的项，如果它小于子窗口的高度。如果用户按下的键是PAGE UP（向上翻页）或PAGE DOWN（向下翻页），则菜单会根据向菜单驱动程序（）发出的请求（REQ_SCR_DPAGE 和REQ_SCR_UPAGE）滚动一页。

### 17.6. 多列菜单
在上面的示例中，您已经了解了如何使用函数set_menu_format（）。我没有提到cols变量（第三个参数）的作用。如果子窗口足够宽，可以选择每行显示多个项。这可以在cols变量中指定。为了使事情更简单，下面的示例不显示这些项的描述。

```cpp
#include <curses.h>
#include <menu.h>

#define ARRAY_SIZE(a) (sizeof(a) / sizeof(a[0]))
#define CTRLD 	4

char *choices[] = {
                        "Choice 1", "Choice 2", "Choice 3", "Choice 4", "Choice 5",
			"Choice 6", "Choice 7", "Choice 8", "Choice 9", "Choice 10",
			"Choice 11", "Choice 12", "Choice 13", "Choice 14", "Choice 15",
			"Choice 16", "Choice 17", "Choice 18", "Choice 19", "Choice 20",
                        "Exit",
                        (char *)NULL,
                  };

int main()
{	ITEM **my_items;
	int c;
	MENU *my_menu;
        WINDOW *my_menu_win;
        int n_choices, i;

	/* Initialize curses */
	initscr();
	start_color();
        cbreak();
        noecho();
	keypad(stdscr, TRUE);
	init_pair(1, COLOR_RED, COLOR_BLACK);
	init_pair(2, COLOR_CYAN, COLOR_BLACK);

	/* Create items */
        n_choices = ARRAY_SIZE(choices);
        my_items = (ITEM **)calloc(n_choices, sizeof(ITEM *));
        for(i = 0; i < n_choices; ++i)
                my_items[i] = new_item(choices[i], choices[i]);

	/* Crate menu */
	my_menu = new_menu((ITEM **)my_items);

	/* Set menu option not to show the description */
	menu_opts_off(my_menu, O_SHOWDESC);

	/* Create the window to be associated with the menu */
        my_menu_win = newwin(10, 70, 4, 4);
        keypad(my_menu_win, TRUE);

	/* Set main window and sub window */
        set_menu_win(my_menu, my_menu_win);
        set_menu_sub(my_menu, derwin(my_menu_win, 6, 68, 3, 1));
	set_menu_format(my_menu, 5, 3);
	set_menu_mark(my_menu, " * ");

	/* Print a border around the main window and print a title */
        box(my_menu_win, 0, 0);

	attron(COLOR_PAIR(2));
	mvprintw(LINES - 3, 0, "Use PageUp and PageDown to scroll");
	mvprintw(LINES - 2, 0, "Use Arrow Keys to navigate (F1 to Exit)");
	attroff(COLOR_PAIR(2));
	refresh();

	/* Post the menu */
	post_menu(my_menu);
	wrefresh(my_menu_win);

	while((c = wgetch(my_menu_win)) != KEY_F(1))
	{       switch(c)
	        {	case KEY_DOWN:
				menu_driver(my_menu, REQ_DOWN_ITEM);
				break;
			case KEY_UP:
				menu_driver(my_menu, REQ_UP_ITEM);
				break;
			case KEY_LEFT:
				menu_driver(my_menu, REQ_LEFT_ITEM);
				break;
			case KEY_RIGHT:
				menu_driver(my_menu, REQ_RIGHT_ITEM);
				break;
			case KEY_NPAGE:
				menu_driver(my_menu, REQ_SCR_DPAGE);
				break;
			case KEY_PPAGE:
				menu_driver(my_menu, REQ_SCR_UPAGE);
				break;
		}
                wrefresh(my_menu_win);
	}

	/* Unpost and free all the memory taken up */
        unpost_menu(my_menu);
        free_menu(my_menu);
        for(i = 0; i < n_choices; ++i)
                free_item(my_items[i]);
	endwin();
}
```
观察函数调用以set_menu_format（）。它将列数指定为3，因此每行显示3项。我们还关闭了功能menu_opts_off（）的显示说明。有两个函数set_menu_opts（）、menu_opts_on（）和menu_opts（），可用于操作菜单选项。可以指定以下菜单选项。

```cpp
      O_ONEVALUE
            Only one item can be selected for this menu.

       O_SHOWDESC
            Display  the  item  descriptions  when  the  menu  is
            posted.

       O_ROWMAJOR
            Display the menu in row-major order.

       O_IGNORECASE
            Ignore the case when pattern-matching.

       O_SHOWMATCH
            Move the cursor to within the item  name  while  pat­
            tern-matching.

       O_NONCYCLIC
            Don't   wrap   around  next-item  and  previous-item,
            requests to the other end of the menu.
```
默认情况下，所有选项都处于启用状态。可以使用menu_opts_on（）和menu_opts_off（）函数打开或关闭特定属性。您还可以使用set_menu_opts（）直接指定选项。此函数的参数应该是上述某些常量的OR ed值。函数menu_opts（）可用于查找菜单的当前选项。

### 17.7. 多值菜单
您可能想知道，如果您关闭了O_ONEVALUE选项会怎么样。然后菜单变为多值菜单。这意味着您可以选择多个项目。这将带我们到请求REQ_TOGGLE_ITEM。让我们看看它的实际效果。

```cpp
#include <curses.h>
#include <menu.h>

#define ARRAY_SIZE(a) (sizeof(a) / sizeof(a[0]))
#define CTRLD 	4

char *choices[] = {
                        "Choice 1",
                        "Choice 2",
                        "Choice 3",
                        "Choice 4",
			"Choice 5",
			"Choice 6",
			"Choice 7",
                        "Exit",
                  };

int main()
{	ITEM **my_items;
	int c;
	MENU *my_menu;
        int n_choices, i;
	ITEM *cur_item;

	/* Initialize curses */
	initscr();
        cbreak();
        noecho();
	keypad(stdscr, TRUE);

	/* Initialize items */
        n_choices = ARRAY_SIZE(choices);
        my_items = (ITEM **)calloc(n_choices + 1, sizeof(ITEM *));
        for(i = 0; i < n_choices; ++i)
                my_items[i] = new_item(choices[i], choices[i]);
	my_items[n_choices] = (ITEM *)NULL;

	my_menu = new_menu((ITEM **)my_items);

	/* Make the menu multi valued */
	menu_opts_off(my_menu, O_ONEVALUE);

	mvprintw(LINES - 3, 0, "Use <SPACE> to select or unselect an item.");
	mvprintw(LINES - 2, 0, "<ENTER> to see presently selected items(F1 to Exit)");
	post_menu(my_menu);
	refresh();

	while((c = getch()) != KEY_F(1))
	{       switch(c)
	        {	case KEY_DOWN:
				menu_driver(my_menu, REQ_DOWN_ITEM);
				break;
			case KEY_UP:
				menu_driver(my_menu, REQ_UP_ITEM);
				break;
			case ' ':
				menu_driver(my_menu, REQ_TOGGLE_ITEM);
				break;
			case 10:	/* Enter */
			{	char temp[200];
				ITEM **items;

				items = menu_items(my_menu);
				temp[0] = '\0';
				for(i = 0; i < item_count(my_menu); ++i)
					if(item_value(items[i]) == TRUE)
					{	strcat(temp, item_name(items[i]));
						strcat(temp, " ");
					}
				move(20, 0);
				clrtoeol();
				mvprintw(20, 0, temp);
				refresh();
			}
			break;
		}
	}

	free_item(my_items[0]);
        free_item(my_items[1]);
	free_menu(my_menu);
	endwin();
}

```
哇，很多新功能。让我们一个接一个地吃吧。首先，REQ_TOGGLE_ITEM。在多值菜单中，应允许用户选择或取消选择多个项目。请求 REQ_TOGGLE_ITEM 用于切换当前选择。在这种情况下，当按下空格时，请求REQ_TOGGLE_ITEM 请求被发送到menu_driver以实现结果。

现在，当用户按下<ENTER>时，我们显示他当前选择的项目。首先，我们使用函数menu_items（）找出与菜单关联的项。然后我们循环遍历这些项，以确定是否选中了该项。如果选择了项，函数item_value（）将返回TRUE。函数item_count（）返回菜单中的项数。可以使用item_name（）找到项名称。您还可以使用item_description（）查找与项关联的描述。

### 17.8. 菜单选项
嗯，这个时候你一定很想在菜单上有所不同，有很多功能。我知道。你想要颜色！！！。你想创建类似于那些文本模式dos游戏的漂亮菜单。函数set_menu_fore（）和set_menu_back（）可用于更改选定项和未选定项的属性。这些名字有误导性。他们不会改变菜单的前景或背景，这将是无用的。
函数set_menu_grey（）可用于设置菜单中不可选择项的显示属性。这就给我们带来了一个有趣的选项，它是唯一一个O_SELECTABLE的选项。我们可以通过函数item_opts_off（）将其关闭，然后该项就不可选择了。就像那些花哨的窗口菜单中的灰色项目。让我们用这个例子来实践这些概念

```cpp
#include <menu.h>

#define ARRAY_SIZE(a) (sizeof(a) / sizeof(a[0]))
#define CTRLD 	4

char *choices[] = {
                        "Choice 1",
                        "Choice 2",
                        "Choice 3",
                        "Choice 4",
			"Choice 5",
			"Choice 6",
			"Choice 7",
                        "Exit",
                  };

int main()
{	ITEM **my_items;
	int c;
	MENU *my_menu;
        int n_choices, i;
	ITEM *cur_item;

	/* Initialize curses */
	initscr();
	start_color();
        cbreak();
        noecho();
	keypad(stdscr, TRUE);
	init_pair(1, COLOR_RED, COLOR_BLACK);
	init_pair(2, COLOR_GREEN, COLOR_BLACK);
	init_pair(3, COLOR_MAGENTA, COLOR_BLACK);

	/* Initialize items */
        n_choices = ARRAY_SIZE(choices);
        my_items = (ITEM **)calloc(n_choices + 1, sizeof(ITEM *));
        for(i = 0; i < n_choices; ++i)
                my_items[i] = new_item(choices[i], choices[i]);
	my_items[n_choices] = (ITEM *)NULL;
	item_opts_off(my_items[3], O_SELECTABLE);
	item_opts_off(my_items[6], O_SELECTABLE);

	/* Create menu */
	my_menu = new_menu((ITEM **)my_items);

	/* Set fore ground and back ground of the menu */
	set_menu_fore(my_menu, COLOR_PAIR(1) | A_REVERSE);
	set_menu_back(my_menu, COLOR_PAIR(2));
	set_menu_grey(my_menu, COLOR_PAIR(3));

	/* Post the menu */
	mvprintw(LINES - 3, 0, "Press <ENTER> to see the option selected");
	mvprintw(LINES - 2, 0, "Up and Down arrow keys to naviage (F1 to Exit)");
	post_menu(my_menu);
	refresh();

	while((c = getch()) != KEY_F(1))
	{       switch(c)
	        {	case KEY_DOWN:
				menu_driver(my_menu, REQ_DOWN_ITEM);
				break;
			case KEY_UP:
				menu_driver(my_menu, REQ_UP_ITEM);
				break;
			case 10: /* Enter */
				move(20, 0);
				clrtoeol();
				mvprintw(20, 0, "Item selected is : %s",
						item_name(current_item(my_menu)));
				pos_menu_cursor(my_menu);
				break;
		}
	}
	unpost_menu(my_menu);
	for(i = 0; i < n_choices; ++i)
		free_item(my_items[i]);
	free_menu(my_menu);
	endwin();
}
```
### 17.9. 有用的用户指针
我们可以将用户指针与菜单中的每个项目相关联。它的工作方式与面板中的用户指针相同。菜单系统不会碰它。你可以在里面存放任何你喜欢的东西。我通常使用它来存储在选择菜单选项时要执行的功能（它被选中，可能是用户按下的<ENTER>）；
```cpp
#include <curses.h>
#include <menu.h>

#define ARRAY_SIZE(a) (sizeof(a) / sizeof(a[0]))
#define CTRLD 	4

char *choices[] = {
                        "Choice 1",
                        "Choice 2",
                        "Choice 3",
                        "Choice 4",
			"Choice 5",
			"Choice 6",
			"Choice 7",
                        "Exit",
                  };
void func(char *name);

int main()
{	ITEM **my_items;
	int c;
	MENU *my_menu;
        int n_choices, i;
	ITEM *cur_item;

	/* Initialize curses */
	initscr();
	start_color();
        cbreak();
        noecho();
	keypad(stdscr, TRUE);
	init_pair(1, COLOR_RED, COLOR_BLACK);
	init_pair(2, COLOR_GREEN, COLOR_BLACK);
	init_pair(3, COLOR_MAGENTA, COLOR_BLACK);

	/* Initialize items */
        n_choices = ARRAY_SIZE(choices);
        my_items = (ITEM **)calloc(n_choices + 1, sizeof(ITEM *));
        for(i = 0; i < n_choices; ++i)
	{       my_items[i] = new_item(choices[i], choices[i]);
		/* Set the user pointer */
		set_item_userptr(my_items[i], func);
	}
	my_items[n_choices] = (ITEM *)NULL;

	/* Create menu */
	my_menu = new_menu((ITEM **)my_items);

	/* Post the menu */
	mvprintw(LINES - 3, 0, "Press <ENTER> to see the option selected");
	mvprintw(LINES - 2, 0, "Up and Down arrow keys to naviage (F1 to Exit)");
	post_menu(my_menu);
	refresh();

	while((c = getch()) != KEY_F(1))
	{       switch(c)
	        {	case KEY_DOWN:
				menu_driver(my_menu, REQ_DOWN_ITEM);
				break;
			case KEY_UP:
				menu_driver(my_menu, REQ_UP_ITEM);
				break;
			case 10: /* Enter */
			{	ITEM *cur;
				void (*p)(char *);

				cur = current_item(my_menu);
				p = item_userptr(cur);
				p((char *)item_name(cur));
				pos_menu_cursor(my_menu);
				break;
			}
			break;
		}
	}
	unpost_menu(my_menu);
	for(i = 0; i < n_choices; ++i)
		free_item(my_items[i]);
	free_menu(my_menu);
	endwin();
}

void func(char *name)
{	move(20, 0);
	clrtoeol();
	mvprintw(20, 0, "Item selected is : %s", name);
```
