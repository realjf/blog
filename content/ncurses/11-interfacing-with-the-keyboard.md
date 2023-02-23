---
title: "NCURSES编程 之 11.键盘接口 11 Interfacing With the Keyboard"
date: 2019-03-05T10:39:16+08:00
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

## 11. 键盘接口

### 11.1. 基础知识
没有强大的用户界面就没有完整的GUI，要与用户交互，curses程序应该对用户的按键或鼠标动作敏感。我们先来处理按键吧。

正如您在上面几乎所有的示例中所看到的，从用户那里获取按键输入非常容易。获取按键的一种简单方法是使用getch（）函数。当您对读取单个按键点击而不是完整的文本行（通常以回车结束）感兴趣时，应启用cbreak模式来读取按键。应启用键盘以获取功能键、箭头键等。有关详细信息，请参阅初始化部分。

getch（）返回与按下的键对应的整数。如果是普通字符，则整数值将与字符等效。否则，它将返回一个可以与curses.h中定义的常量匹配的数字。例如，如果用户按F1，则返回的整数为265。可以使用curses.h中定义的宏KEY_F()来检查这一点。这使得读取键便于携带和管理。
例如，如果像这样调用getch（）
```cpp
int ch;

ch = getch();
```
getch（）将等待用户按键（除非指定了超时），当用户按键时，将返回相应的整数。然后，您可以使用curses.h中定义的常量检查返回的值，以便与所需的键匹配。

下面的代码段将完成这项工作。

```cpp
 if(ch == KEY_LEFT)
        printw("Left arrow is pressed\n");
```
让我们编写一个小程序，创建一个菜单，可以通过上下箭头导航。

### 11.2 一个简单的按键使用示例
```cpp
#include <stdio.h>
#include <ncurses.h>

#define WIDTH 30
#define HEIGHT 10

int startx = 0;
int starty = 0;

char *choices[] = {
			"Choice 1",
			"Choice 2",
			"Choice 3",
			"Choice 4",
			"Exit",
		  };
int n_choices = sizeof(choices) / sizeof(char *);
void print_menu(WINDOW *menu_win, int highlight);

int main()
{	WINDOW *menu_win;
	int highlight = 1;
	int choice = 0;
	int c;

	initscr();
	clear();
	noecho();
	cbreak();	/* Line buffering disabled. pass on everything */
	startx = (80 - WIDTH) / 2;
	starty = (24 - HEIGHT) / 2;

	menu_win = newwin(HEIGHT, WIDTH, starty, startx);
	keypad(menu_win, TRUE);
	mvprintw(0, 0, "Use arrow keys to go up and down, Press enter to select a choice");
	refresh();
	print_menu(menu_win, highlight);
	while(1)
	{	c = wgetch(menu_win);
		switch(c)
		{	case KEY_UP:
				if(highlight == 1)
					highlight = n_choices;
				else
					--highlight;
				break;
			case KEY_DOWN:
				if(highlight == n_choices)
					highlight = 1;
				else
					++highlight;
				break;
			case 10:
				choice = highlight;
				break;
			default:
				mvprintw(24, 0, "Charcter pressed is = %3d Hopefully it can be printed as '%c'", c, c);
				refresh();
				break;
		}
		print_menu(menu_win, highlight);
		if(choice != 0)	/* User did a choice come out of the infinite loop */
			break;
	}
	mvprintw(23, 0, "You chose choice %d with choice string %s\n", choice, choices[choice - 1]);
	clrtoeol();
	refresh();
	endwin();
	return 0;
}


void print_menu(WINDOW *menu_win, int highlight)
{
	int x, y, i;

	x = 2;
	y = 2;
	box(menu_win, 0, 0);
	for(i = 0; i < n_choices; ++i)
	{	if(highlight == i + 1) /* High light the present choice */
		{	wattron(menu_win, A_REVERSE);
			mvwprintw(menu_win, y, x, "%s", choices[i]);
			wattroff(menu_win, A_REVERSE);
		}
		else
			mvwprintw(menu_win, y, x, "%s", choices[i]);
		++y;
	}
	wrefresh(menu_win);
}
```


