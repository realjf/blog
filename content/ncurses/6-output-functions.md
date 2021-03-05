---
title: "NCURSES编程 之 6.输出函数 6 Output Functions"
date: 2021-03-05T00:23:31+08:00
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

## 6. 输出函数

我想你已经等不及要看一些行动了。回到我们的curses之旅。现在curses已经初始化，让我们和世界互动。

有三类函数可用于在屏幕上进行输出。
- addch（）类：打印带有属性的单个字符
- printw（）类：类似printf（）的打印格式化输出
- addstr（）类：打印字符串
这些函数可以互换使用，使用哪一个类是风格问题。让我们详细看看每一个。

### 6.1 addch() 类的函数

这些函数将单个字符放入当前光标位置，并推进光标的位置。您可以指定要打印的字符，但它们通常用于打印具有某些属性的字符。属性将在文档的后面部分详细解释。如果角色与属性（粗体、反转视频等）关联，则当curses打印角色时，它将在该属性中打印。

要将角色与某些属性组合在一起，有两个选项：

- 通过使用所需的属性宏或单个字符。这些属性宏可以在头文件ncurses.h中找到。例如，要打印粗体加下划线的字符ch（char类型），可以调用addch（），如下所示。
```cpp
addch(ch | A_BOLD | A_UNDERLINE);
```
- 通过使用类似attrset（）、attron（）、attroff（）的函数。这些函数在属性部分进行了说明。简单地说，它们操纵给定窗口的当前属性。设置后，窗口中打印的字符将与属性相关联，直到关闭为止。

此外，curses为基于字符的图形提供了一些特殊字符。可以绘制表格、水平线或垂直线等。可以在头文件ncurses.h中找到所有可用字符。请尝试在该文件中查找以ACS_开头的宏。
### 6.2 mvaddch(),waddch()和 mvwaddch()
mvaddch()用于移动光标到指定点，然后打印，因此，如下调用：
```cpp
move(row,col);    /* moves the cursor to rowth row and colth column */
addch(ch);
```
可以代替
```cpp
mvaddch(row,col,ch);
```
waddch（）与addch（）类似，只是它将字符添加到给定的窗口中。（请注意，addch（）将一个字符添加到窗口stdscr中。）

以类似的方式，mvwaddch（）函数用于在给定的坐标处将字符添加到给定的窗口中。

现在，我们熟悉了基本的输出函数addch（）。但是，如果我们想打印一个字符串，那么逐字打印会非常烦人。幸运的是，ncurses提供了printf-like或puts-like函数。

### 6.3. printw（）函数类
这些函数类似于printf（），增加了在屏幕上任何位置打印的功能。

#### 6.3.1. printw（）和mvprintw
这两个函数的工作方式与printf（）非常相似。mvprintw（）可用于将光标移动到某个位置，然后打印。如果要先移动光标，然后使用printw（）函数打印，请先使用move（），然后使用printw（），尽管我看不出为什么要避免使用mvprintw（），但您可以灵活地进行操作。

#### 6.3.2. wprintw（）和mvwprintw
这两个函数与上述两个函数类似，只是它们打印在作为参数给出的相应窗口中。

#### 6.3.3. vwprintw（）
此函数类似于vprintf（）。当要打印可变数量的参数时，可以使用此选项。

#### 6.3.4. 一个简单的printw示例

```cpp
#include <ncurses.h>			/* ncurses.h includes stdio.h */  
#include <string.h> 
 
int main()
{
 char mesg[]="Just a string";		/* message to be appeared on the screen */
 int row,col;				/* to store the number of rows and *
					 * the number of colums of the screen */
 initscr();				/* start the curses mode */
 getmaxyx(stdscr,row,col);		/* get the number of rows and columns */
 mvprintw(row/2,(col-strlen(mesg))/2,"%s",mesg);
                                	/* print the message at the center of the screen */
 mvprintw(row-2,0,"This screen has %d rows and %d columns\n",row,col);
 printw("Try resizing your window(if possible) and then run this program again");
 refresh();
 getch();
 endwin();

 return 0;
}
```
上面的程序演示了printw的易用性。你只需输入坐标和要显示在屏幕上的信息，然后它就会做你想做的事情。

上面的程序向我们介绍了一个新函数getmaxyx（），一个在ncurses.h中定义的宏。它给出了给定窗口中的列数和行数。getmaxyx（）通过更新给定给它的变量来实现这一点。因为getmaxyx（）不是一个函数，所以我们不向它传递指针，只给出两个整数变量。

### 6.4 addstr()类的函数
addstr（）用于将字符串放入给定窗口。此函数类似于为给定字符串中的每个字符调用一次addch（）。这适用于所有输出函数。这个家族中还有其他一些函数，如mvaddstr（）、mvwaddstr（）和waddstr（），它们遵循诅咒的命名约定。（例如，mvaddstr（）类似于分别调用move（）和addstr（）。）这个家族的另一个函数是addnstr（），它另外接受一个整数参数（比如n）。此函数最多可在屏幕中输入n个字符。如果n是负数，那么将添加整个字符串。

### 6.5 一句警告
所有这些函数在它们的参数中首先采用y坐标，然后采用x坐标。初学者的一个常见错误是按那个顺序传递x，y。如果对（y，x）坐标的操作太多，请考虑将屏幕划分为多个窗口，并分别对每个窗口进行操作。有关窗口的说明，请参见“窗口”部分。
