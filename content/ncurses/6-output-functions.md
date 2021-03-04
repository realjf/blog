---
title: "6 Output Functions"
date: 2021-03-05T00:23:31+08:00
keywords: ["ncurses"]
categories: ["ncurses"]
tags: ["ncurses"]
series: [""]
draft: true
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

