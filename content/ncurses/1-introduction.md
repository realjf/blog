---
title: "NCURSES编程 之 1.简介 1 Introduction"
date: 2019-03-04T22:53:29+08:00
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

## 1. 简介

在老式电传终端时代，终端远离计算机，通过串行电缆与计算机相连。终端可以通过发送一系列字节来配置。终端的所有功能（如将光标移动到新位置、擦除部分屏幕、滚动屏幕、更改模式等）都可以通过这些字节序列访问。这些控制序列通常称为转义序列，因为它们以转义（0x1B）字符开头。即使在今天，通过适当的仿真，我们也可以将转义序列发送到仿真器，并在终端窗口上实现相同的效果。

假设你想用彩色打印一行。试着在你的控制台上输入这个。

```sh
echo "^[[0;31;40mIn Color"
```

第一个字符是转义字符，看起来像两个字符^和[。要打印它，您必须按CTRL+V，然后按ESC键（或者直接用\033代替）。其他的都是普通的可打印字符。你应该可以看到红色的字符串“In Color”。它保持这种方式，并恢复到原来的模式类型。

```sh
echo "^[[0;37;40m"
```

现在，这些神奇的字符是什么意思？难以理解？对于不同的终端，它们甚至可能是不同的。因此UNIX的设计者发明了一种叫做termcap的机制。它是一个文件，列出了特定终端的所有功能，以及实现特定效果所需的转义序列。在后来的几年里，它被terminfo所取代。这种机制不需要深入研究太多细节，它允许应用程序查询terminfo数据库并获取要发送到终端或终端仿真器的控制字符。

### 1.1 什么是NCURSES？

你可能想知道，这些技术上的胡言乱语有什么意义。在上述场景中，每个应用程序都应该查询terminfo并执行必要的操作（发送控制字符等）。很快就很难处理这种复杂性，这就产生了“CURSES”。Curses是“cursor optimization”这个名字的双关语。Curses库在使用原始终端代码时形成了一个包装器，并提供了高度灵活和高效的API（应用程序编程接口）。它提供了移动光标、创建窗口、生成颜色、玩鼠标等功能。应用程序不必担心底层的终端功能。

那么什么是NCURSES？NCURSES是原始systemv 4.0版（SVr4）curses的克隆。它是一个可自由分发的库，与旧版本的curses完全兼容。简而言之，它是一个函数库，用于管理应用程序在字符单元终端上的显示。在本文档的其余部分中，术语“curses”和“ncurses”可以互换使用。

NCURSES的详细历史记录可以在源发行版的新闻文件中找到。当前包由托马斯·迪基维护。你可以联系维修人员bug-ncurses@gnu.org。

### 1.2 用NCURSES我们可以做什么？

NCURSES不仅在终端功能上创建了一个包装器，而且还提供了一个健壮的框架来在文本模式下创建美观的UI（用户界面）。它提供了创建窗口等函数。它的姊妹库面板、菜单和窗体提供了对基本curses库的扩展。这些库通常伴随着curses。可以创建包含多个窗口、菜单、面板和窗体的应用程序。窗口可以独立管理，可以提供“滚动性”，甚至可以隐藏。

菜单为用户提供了一个简单的命令选择选项。窗体允许创建易于使用的数据输入和显示窗口。面板扩展了ncurses处理重叠和堆叠窗口的功能。

这些只是我们可以用ncurses做的一些基本的事情。随着我们的讲述，我们将看到这些库的所有功能。

### 1.3 哪里可以获取到？

好吧，现在你知道你能用ncurses做什么了，你必须开始了。NCURSES通常随安装一起提供。如果你没有这个库或者想自己编译它，请继续阅读。

#### 编译包

NCURSES 可从[ftp://ftp.gnu.org/pub/gnu/ncurses/ncurses.tar.gz](ftp://ftp.gnu.org/pub/gnu/ncurses/ncurses.tar.gz)或任何[http://www.gnu.org/order/ftp.html](http://www.gnu.org/order/ftp.html)中提到的ftp站点。

阅读自述文件和安装文件，了解如何安装它的详细信息。它通常包括以下操作。

```sh
# 解压
tar zxvf ncurses<version>.tar.gz
# 进入目录
cd ncurses<version>
# 配置构建信息
./configure
# 构建
make
# 安装
make install
```

#### 使用rpm

NCURSES RPM 能在<http://rpmfind.net中找到并下载，然后安装它>

```sh
rpm -i <downloaded rpm>
```

### 1.4 该文档的目的/范围

本文档旨在成为使用ncurses及其姊妹库进行编程的“一体式”指南。我们从一个简单的“helloworld”程序毕业到更复杂的表单操作。假设没有ncurses的经验。写作是非正式的，但是每一个例子都提供了很多细节。

### 1.5 关于编程

文档中的所有程序都以压缩格式提供[这里](http://www.tldp.org/HOWTO/NCURSES-Programming-HOWTO/ncurses_programs.tar.gz)。解压缩和解压。目录结构如下所示。

```sh
ncurses
   |
   |----> JustForFun     -- just for fun programs
   |----> basics         -- basic programs
   |----> demo           -- output files go into this directory after make
   |          |
   |          |----> exe -- exe files of all example programs
   |----> forms          -- programs related to form library
   |----> menus          -- programs related to menus library
   |----> panels         -- programs related to panels library
   |----> perl           -- perl equivalents of the examples (contributed
   |                            by Anuradha Ratnaweera)
   |----> Makefile       -- the top level Makefile
   |----> README         -- the top level README file. contains instructions
   |----> COPYING        -- copyright notice
```

各个目录包含以下文件。

```sh
Description of files in each directory
--------------------------------------
JustForFun
    |
    |----> hanoi.c   -- The Towers of Hanoi Solver
    |----> life.c    -- The Game of Life demo
    |----> magic.c   -- An Odd Order Magic Square builder
    |----> queens.c  -- The famous N-Queens Solver
    |----> shuffle.c -- A fun game, if you have time to kill
    |----> tt.c      -- A very trivial typing tutor

  basics
    |
    |----> acs_vars.c            -- ACS_ variables example
    |----> hello_world.c         -- Simple "Hello World" Program
    |----> init_func_example.c   -- Initialization functions example
    |----> key_code.c            -- Shows the scan code of the key pressed
    |----> mouse_menu.c          -- A menu accessible by mouse
    |----> other_border.c        -- Shows usage of other border functions apa
    |                               -- rt from box()
    |----> printw_example.c      -- A very simple printw() example
    |----> scanw_example.c       -- A very simple getstr() example
    |----> simple_attr.c         -- A program that can print a c file with
    |                               -- comments in attribute
    |----> simple_color.c        -- A simple example demonstrating colors
    |----> simple_key.c          -- A menu accessible with keyboard UP, DOWN
    |                               -- arrows
    |----> temp_leave.c          -- Demonstrates temporarily leaving curses mode
    |----> win_border.c          -- Shows Creation of windows and borders
    |----> with_chgat.c          -- chgat() usage example

  forms
    |
    |----> form_attrib.c     -- Usage of field attributes
    |----> form_options.c    -- Usage of field options
    |----> form_simple.c     -- A simple form example
    |----> form_win.c        -- Demo of windows associated with forms

  menus
    |
    |----> menu_attrib.c     -- Usage of menu attributes
    |----> menu_item_data.c  -- Usage of item_name() etc.. functions
    |----> menu_multi_column.c    -- Creates multi columnar menus
    |----> menu_scroll.c     -- Demonstrates scrolling capability of menus
    |----> menu_simple.c     -- A simple menu accessed by arrow keys
    |----> menu_toggle.c     -- Creates multi valued menus and explains
    |                           -- REQ_TOGGLE_ITEM
    |----> menu_userptr.c    -- Usage of user pointer
    |----> menu_win.c        -- Demo of windows associated with menus

  panels
    |
    |----> panel_browse.c    -- Panel browsing through tab. Usage of user
    |                           -- pointer
    |----> panel_hide.c      -- Hiding and Un hiding of panels
    |----> panel_resize.c    -- Moving and resizing of panels
    |----> panel_simple.c    -- A simple panel example

  perl
    |----> 01-10.pl          -- Perl equivalents of first ten example programs
```

主目录中包含一个顶级Makefile。它构建所有的文件，并将准备好使用的exe放在demo/exe目录中。您也可以通过进入相应的目录来进行选择性生成。每个目录都包含一个自述文件，解释目录中每个c文件的用途。

对于每个示例，我都包含了相对于examples目录的文件路径名。

如果您喜欢浏览单个程序，请将浏览器指向 <http://tldp.org/HOWTO/NCURSES-Programming-HOWTO/ncurses_programs/>

所有程序都是在ncurses（MIT风格）使用的同一个许可证下发布的。这让你有能力做几乎任何事情，而不是声称他们是你的。你可以在你的程序中随意使用它们。

### 1.6 其他格式的文档

本指南也可在网站上以各种其他格式提供tldp.org网站地点。以下是指向此文档其他格式的链接。

#### 1.6.1 来自的现成格式tldp.org网站

- [Acrobat PDF Format](http://www.ibiblio.org/pub/Linux/docs/HOWTO/other-formats/pdf/NCURSES-Programming-HOWTO.pdf)
- [PostScript Format](http://www.ibiblio.org/pub/Linux/docs/HOWTO/other-formats/ps/NCURSES-Programming-HOWTO.ps.gz)
- [In Multiple HTML pages](http://www.ibiblio.org/pub/Linux/docs/HOWTO/other-formats/html/NCURSES-Programming-HOWTO-html.tar.gz)
- [In One big HTML format](http://www.ibiblio.org/pub/Linux/docs/HOWTO/other-formats/html_single/NCURSES-Programming-HOWTO.html)

#### 1.6.2 从源码构建

如果上面的链接断开了，或者您想尝试使用sgml，请继续阅读。

```sh
Get both the source and the tar,gzipped programs, available at
        http://cvsview.tldp.org/index.cgi/LDP/howto/docbook/
        NCURSES-HOWTO/NCURSES-Programming-HOWTO.sgml
        http://cvsview.tldp.org/index.cgi/LDP/howto/docbook/
        NCURSES-HOWTO/ncurses_programs.tar.gz

    Unzip ncurses_programs.tar.gz with
    tar zxvf ncurses_programs.tar.gz

    Use jade to create various formats. For example if you just want to create
    the multiple html files, you would use
        jade -t sgml -i html -d <path to docbook html stylesheet>
        NCURSES-Programming-HOWTO.sgml
    to get pdf, first create a single html file of the HOWTO with
        jade -t sgml -i html -d <path to docbook html stylesheet> -V nochunks
        NCURSES-Programming-HOWTO.sgml > NCURSES-ONE-BIG-FILE.html
    then use htmldoc to get pdf file with
        htmldoc --size universal -t pdf --firstpage p1 -f <output file name.pdf>
        NCURSES-ONE-BIG-FILE.html
    for ps, you would use
        htmldoc --size universal -t ps --firstpage p1 -f <output file name.ps>
        NCURSES-ONE-BIG-FILE.html
```

### 1.7

### 1.8 愿望清单

这是愿望清单，按优先顺序排列。如果你有一个愿望或者你想完成这个愿望，给我发邮件。

- 在表单部分的最后部分添加示例。
- 准备一个展示所有程序的演示，并允许用户浏览每个程序的描述。让用户编译并查看正在运行的程序。首选基于对话框的界面。
- 添加调试信息。_tracef，tracemouse的东西。
- 使用ncurses包提供的函数访问termcap、terminfo。
- 同时在两个终端上工作。
- 在杂项部分添加更多内容。
