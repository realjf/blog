---
title: "NCURSES编程 之 12.鼠标接口 12 Interfacing With the Mouse"
date: 2021-03-05T10:44:02+08:00
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

## 12 鼠标接口
现在您已经了解了如何获取键，让我们从鼠标执行相同的操作。通常每个UI都允许用户与键盘和鼠标进行交互。

### 12.1. 基础知识
在执行任何其他操作之前，必须使用mousemask（）启用要接收的事件。
```cpp
mousemask(  mmask_t newmask,    /* The events you want to listen to */
                mmask_t *oldmask)    /* The old events mask                */
```
上面函数的第一个参数是您想要监听的事件的位掩码。默认情况下，将关闭所有事件。位掩码ALL_MOUSE_EVENTS 可用于获取所有事件。

以下是所有事件掩码：
```text
Name            Description
       ---------------------------------------------------------------------
       BUTTON1_PRESSED          mouse button 1 down
       BUTTON1_RELEASED         mouse button 1 up
       BUTTON1_CLICKED          mouse button 1 clicked
       BUTTON1_DOUBLE_CLICKED   mouse button 1 double clicked
       BUTTON1_TRIPLE_CLICKED   mouse button 1 triple clicked
       BUTTON2_PRESSED          mouse button 2 down
       BUTTON2_RELEASED         mouse button 2 up
       BUTTON2_CLICKED          mouse button 2 clicked
       BUTTON2_DOUBLE_CLICKED   mouse button 2 double clicked
       BUTTON2_TRIPLE_CLICKED   mouse button 2 triple clicked
       BUTTON3_PRESSED          mouse button 3 down
       BUTTON3_RELEASED         mouse button 3 up
       BUTTON3_CLICKED          mouse button 3 clicked
       BUTTON3_DOUBLE_CLICKED   mouse button 3 double clicked
       BUTTON3_TRIPLE_CLICKED   mouse button 3 triple clicked
       BUTTON4_PRESSED          mouse button 4 down
       BUTTON4_RELEASED         mouse button 4 up
       BUTTON4_CLICKED          mouse button 4 clicked
       BUTTON4_DOUBLE_CLICKED   mouse button 4 double clicked
       BUTTON4_TRIPLE_CLICKED   mouse button 4 triple clicked
       BUTTON_SHIFT             shift was down during button state change
       BUTTON_CTRL              control was down during button state change
       BUTTON_ALT               alt was down during button state change
       ALL_MOUSE_EVENTS         report all button state changes
       REPORT_MOUSE_POSITION    report mouse movement
```
### 12.2. 获取事件
一旦一类鼠标事件被启用，getch（）函数类会在每次鼠标事件发生时返回KEY_MOUSE。然后可以使用getmouse（）检索鼠标事件。

代码大致如下所示：
```cpp
MEVENT event;

    ch = getch();
    if(ch == KEY_MOUSE)
        if(getmouse(&event) == OK)
            .    /* Do some thing with the event */
            .
            .
```
getmouse（）将事件返回给它的指针。这是一个包含
```cpp
typedef struct
    {
        short id;         /* ID to distinguish multiple devices */
        int x, y, z;      /* event coordinates */
        mmask_t bstate;   /* button state bits */
    }    
```
bstate是我们感兴趣的主要变量。它告诉鼠标的按键状态。

然后通过下面的代码片段，我们可以找出发生了什么。
```cpp
if(event.bstate & BUTTON1_PRESSED)
        printw("Left Button Pressed");
```
### 12.3. 把它们放在一起
这和鼠标有很大的关系。让我们创建相同的菜单并启用鼠标交互。为了简化操作，删除了按键处理。

例11。用鼠标进入菜单！！！
```cpp
#include <ncurses.h>

#define WIDTH 30
#define HEIGHT 10 

int startx = 0;
int starty = 0;

char *choices[] = { 	"Choice 1",
			"Choice 2",
			"Choice 3",
			"Choice 4",
			"Exit",
		  };

int n_choices = sizeof(choices) / sizeof(char *);

void print_menu(WINDOW *menu_win, int highlight);
void report_choice(int mouse_x, int mouse_y, int *p_choice);

int main()
{	int c, choice = 0;
	WINDOW *menu_win;
	MEVENT event;

	/* Initialize curses */
	initscr();
	clear();
	noecho();
	cbreak();	//Line buffering disabled. pass on everything

	/* Try to put the window in the middle of screen */
	startx = (80 - WIDTH) / 2;
	starty = (24 - HEIGHT) / 2;
	
	attron(A_REVERSE);
	mvprintw(23, 1, "Click on Exit to quit (Works best in a virtual console)");
	refresh();
	attroff(A_REVERSE);

	/* Print the menu for the first time */
	menu_win = newwin(HEIGHT, WIDTH, starty, startx);
	print_menu(menu_win, 1);
	/* Get all the mouse events */
	mousemask(ALL_MOUSE_EVENTS, NULL);
	
	while(1)
	{	c = wgetch(menu_win);
		switch(c)
		{	case KEY_MOUSE:
			if(getmouse(&event) == OK)
			{	/* When the user clicks left mouse button */
				if(event.bstate & BUTTON1_PRESSED)
				{	report_choice(event.x + 1, event.y + 1, &choice);
					if(choice == -1) //Exit chosen
						goto end;
					mvprintw(22, 1, "Choice made is : %d String Chosen is \"%10s\"", choice, choices[choice - 1]);
					refresh(); 
				}
			}
			print_menu(menu_win, choice);
			break;
		}
	}		
end:
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
	{	if(highlight == i + 1)
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

/* Report the choice according to mouse position */
void report_choice(int mouse_x, int mouse_y, int *p_choice)
{	int i,j, choice;

	i = startx + 2;
	j = starty + 3;
	
	for(choice = 0; choice < n_choices; ++choice)
		if(mouse_y == j + choice && mouse_x >= i && mouse_x <= i + strlen(choices[choice]))
		{	if(choice == n_choices - 1)
				*p_choice = -1;		
			else
				*p_choice = choice + 1;	
			break;
		}
}
```
12.4. 其他函数
函数mouse_trafo（）和wmouse_trafo（）可用于将鼠标坐标转换为屏幕相对坐标。有关详细信息，请参阅curs_mouse(3X) 手册页。

mouseinterval函数设置在按下和释放事件之间可以经过的最长时间（以千秒为单位），以便将它们识别为单击。此函数返回上一个间隔值。默认值为五分之一秒。


