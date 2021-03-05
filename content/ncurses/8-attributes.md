---
title: "NCURSES编程 之 8.属性 8 Attributes"
date: 2021-03-05T09:43:14+08:00
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

## 8. 属性
我们已经看到了如何使用属性打印具有某些特殊效果的字符的示例。如果谨慎地设置属性，可以以简单易懂的方式呈现信息。下面的程序将一个C文件作为输入并打印带有粗体注释的文件。扫描代码。

一个简单的属性例子：
```cpp
/* pager functionality by Joseph Spainhour" <spainhou@bellsouth.net> */
#include <ncurses.h>
#include <stdlib.h>

int main(int argc, char *argv[])
{ 
  int ch, prev, row, col;
  prev = EOF;
  FILE *fp;
  int y, x;

  if(argc != 2)
  {
    printf("Usage: %s <a c file name>\n", argv[0]);
    exit(1);
  }
  fp = fopen(argv[1], "r");
  if(fp == NULL)
  {
    perror("Cannot open input file");
    exit(1);
  }
  initscr();				/* Start curses mode */
  getmaxyx(stdscr, row, col);		/* find the boundaries of the screeen */
  while((ch = fgetc(fp)) != EOF)	/* read the file till we reach the end */
  {
    getyx(stdscr, y, x);		/* get the current curser position */
    if(y == (row - 1))			/* are we are at the end of the screen */
    {
      printw("<-Press Any Key->");	/* tell the user to press a key */
      getch();
      clear();				/* clear the screen */
      move(0, 0);			/* start at the beginning of the screen */
    }
    if(prev == '/' && ch == '*')    	/* If it is / and * then only
                                     	 * switch bold on */    
    {
      attron(A_BOLD);			/* cut bold on */
      getyx(stdscr, y, x);		/* get the current curser position */
      move(y, x - 1);			/* back up one space */
      printw("%c%c", '/', ch); 		/* The actual printing is done here */
    }
    else
      printw("%c", ch);
    refresh();
    if(prev == '*' && ch == '/')
      attroff(A_BOLD);        		/* Switch it off once we got *
                                 	 * and then / */
    prev = ch;
  }
  endwin();                       	/* End curses mode */
  fclose(fp);
  return 0;
}
```
别担心那些初始化之类的废话。专注于while循环。它读取文件中的每个字符并搜索模式/*。一旦它发现了模式，它就会用attron（）打开BOLD属性。当我们得到模式*/它被attroff（）关闭。

上面的程序还向我们介绍了两个有用的函数getyx（）和move（）。第一个函数将当前光标的坐标输入变量y，x。由于getyx（）是一个宏，我们不必向变量传递指针。函数move（）将光标移动到给定的坐标。

上面的程序其实很简单，做的不多。在这些行上，人们可以编写一个更有用的程序来读取C文件，解析它并以不同的颜色打印它。人们甚至可以把它扩展到其他语言。

### 8.1. 细节
让我们深入了解属性的更多细节。函数attron（）、attroff（）、attrset（）及其姐妹函数attr_get（）等。。可用于打开/关闭属性、获取属性和生成彩色显示。

函数attron和attroff获取属性的位掩码，并分别打开或关闭它们。<curses.h>中定义的以下视频属性可以传递给这些函数。
```text
    A_NORMAL        Normal display (no highlight)
    A_STANDOUT      Best highlighting mode of the terminal.
    A_UNDERLINE     Underlining
    A_REVERSE       Reverse video
    A_BLINK         Blinking
    A_DIM           Half bright
    A_BOLD          Extra bright or bold
    A_PROTECT       Protected mode
    A_INVIS         Invisible or blank mode
    A_ALTCHARSET    Alternate character set
    A_CHARTEXT      Bit-mask to extract a character
    COLOR_PAIR(n)   Color-pair number n 
```
最后一个是最丰富多彩的颜色：-）颜色将在下一节中解释。

我们可以使用或（|）任何数量的上述属性来获得组合效果。如果你想反向视频与闪烁的字符，你可以使用
```cpp
attron(A_REVERSE | A_BLINK);
```
### 8.2. attron（）与attrset（）
那么attron（）和attrset（）之间有什么区别呢？attrset设置window的属性，而attron只打开给定给它的属性。因此attrset（）完全覆盖窗口以前拥有的任何属性，并将其设置为新属性。类似地，attroff（）只是关闭作为参数提供给它的属性。这给了我们管理属性的灵活性很容易，但是如果你不小心使用它们，你可能会忘记窗口有哪些属性，并使显示混乱。这在管理带有颜色和突出显示的菜单时尤其如此。所以决定一个一致的政策并坚持下去。您可以始终使用standend（），它相当于attrset（A_NORMAL），它关闭所有属性并将您带到NORMAL模式。

### 8.3. attr_get（）
函数attr_get（）获取窗口的当前属性和颜色对。虽然我们可能不会像上面的函数那样经常使用它，但它在扫描屏幕区域时很有用。假设我们想在屏幕上做一些复杂的更新，但我们不确定每个角色与哪个属性相关。然后此函数可以与attrset或attron一起使用，以产生所需的效果。

### 8.4. attr_函数
有一系列函数，如attr_set（）、attr_on等。。这些函数与上述函数类似，只是它们采用attr_t类型的参数。

### 8.5. wattr函数
对于上述每一个函数，我们都有一个对应的函数，它在特定的窗口上运行。上述功能在stdscr上运行。

### 8.6. chgat（）函数
函数chgat（）列在手册页curs_attr的末尾。它实际上是一个有用的。此函数可用于在不移动的情况下为一组字符设置属性。我是认真的！！！不移动光标：-）它从当前光标位置开始更改给定数量字符的属性。
我们可以给-1作为字符计数，以更新到行尾。如果要将字符的属性从当前位置更改为行尾，只需使用以下命令。
```cpp
 chgat(-1, A_REVERSE, 0, NULL);
```
当更改屏幕上已有字符的属性时，此函数非常有用。移动到要从中更改的角色并更改属性。
其他函数wchgat（）、mvchgat（）、wchgat（）的行为类似，只是w函数对特定窗口进行操作。mv函数首先移动光标，然后执行给定的工作。实际上chgat是一个宏，它被一个wchgat（）替换，stdscr作为窗口。大多数“无w”函数都是宏。

chgat()使用示例
```cpp
#include <ncurses.h>

int main(int argc, char *argv[])
{	initscr();			/* Start curses mode 		*/
	start_color();			/* Start color functionality	*/
	
	init_pair(1, COLOR_CYAN, COLOR_BLACK);
	printw("A Big string which i didn't care to type fully ");
	mvchgat(0, 0, -1, A_BLINK, 1, NULL);	
	/* 
	 * First two parameters specify the position at which to start 
	 * Third parameter number of characters to update. -1 means till 
	 * end of line
	 * Forth parameter is the normal attribute you wanted to give 
	 * to the charcter
	 * Fifth is the color index. It is the index given during init_pair()
	 * use 0 if you didn't want color
	 * Sixth one is always NULL 
	 */
	refresh();
  getch();
	endwin();			/* End curses mode		  */
	return 0;
}
```
这个例子还向我们介绍了curses的颜色世界。颜色将在后面详细解释。使用0表示无颜色。

