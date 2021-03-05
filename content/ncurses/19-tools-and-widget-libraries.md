---
title: "NCURSES编程 之 19 工具和小部件库 19 Tools and Widget Libraries"
date: 2021-03-05T14:36:09+08:00
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

## 19 工具和小部件库
现在您已经看到了NCURSE及其姊妹库的功能，您将为一个严重操纵屏幕的项目卷起袖子，准备就绪。但是等等。。在普通的NCURSE中，甚至在附加库中编写和维护复杂的GUI小部件可能相当困难。有一些现成的工具和小部件库可以用来代替编写自己的小部件。您可以使用其中的一些，从代码中获取想法，甚至扩展它们。

### 19.1. CDK（CUSSES开发工具包）
用作者的话说

CDK代表“curses开发工具包”，目前它包含21个随时可用的小部件，这有助于全屏幕诅咒程序的快速开发。

该工具包提供了一些有用的小部件，这些小部件可以直接用于程序中。它写得很好，文档也很好。示例目录中的示例可以是初学者的一个好开始。CDK可从中下载http://insigner-island.net/cdk/. 按照README文件中的说明安装。

#### 19.1.1。小部件列表
下面是cdk提供的小部件列表及其描述。

```text
Widget Type           Quick Description
===========================================================================
Alphalist             Allows a user to select from a list of words, with
                      the ability to narrow the search list by typing in a
                      few characters of the desired word.
Buttonbox             This creates a multiple button widget. 
Calendar              Creates a little simple calendar widget.
Dialog                Prompts the user with a message, and the user
                      can pick an answer from the buttons provided.
Entry                 Allows the user to enter various types of information.
File Selector         A file selector built from Cdk base widgets. This
                      example shows how to create more complicated widgets
                      using the Cdk widget library.
Graph                 Draws a graph.
Histogram             Draws a histogram.
Item List             Creates a pop up field which allows the user to select
                      one of several choices in a small field. Very useful
                      for things like days of the week or month names.
Label                 Displays messages in a pop up box, or the label can be
                      considered part of the screen.
Marquee               Displays a message in a scrolling marquee.
Matrix                Creates a complex matrix with lots of options.
Menu                  Creates a pull-down menu interface.
Multiple Line Entry   A multiple line entry field. Very useful
                      for long fields. (like a description
                      field)
Radio List            Creates a radio button list.
Scale                 Creates a numeric scale. Used for allowing a user to
                      pick a numeric value and restrict them to a range of 
                      values.
Scrolling List        Creates a scrolling list/menu list.
Scrolling Window      Creates a scrolling log file viewer. Can add 
                      information into the window while its running. 
                      A good widget for displaying the progress of
                      something. (akin to a console window)
Selection List        Creates a multiple option selection list.
Slider                Akin to the scale widget, this widget provides a
                      visual slide bar to represent the numeric value.
Template              Creates a entry field with character sensitive 
                      positions. Used for pre-formatted fields like
                      dates and phone numbers.
Viewer                This is a file/information viewer. Very useful
                      when you need to display loads of information.
===========================================================================
```

一些小部件是由thomasdickey在最新版本中修改的。

#### 19.1.2. 一些吸引人的特征
除了使用容易使用的小部件使我们的生活更轻松之外，cdk还解决了一个令人沮丧的问题：打印多色字符串，优雅地对齐字符串。特殊格式标记可以嵌入到传递给CDK函数的字符串中。例如

如果字符串
```cpp
"</B/1>This line should have a yellow foreground and a blue
background.<!1>"
```
作为newCDKLabel（）的参数，它打印前景为黄色、背景为蓝色的行。还有其他标签可用于证明字符串，嵌入特殊绘图字符等。。有关详细信息，请参阅手册页cdk\ U显示屏（3X）。手册页用很好的例子解释了用法。

#### 19.1.3. 结论
总之，CDK是一个编写良好的小部件包，如果使用得当，它可以形成一个强大的框架，用于开发复杂的GUI。

### 19.2. 对话框
很久以前，1994年9月，很少有人知道linux，jefftranter在linux杂志上写了一篇关于dialog的文章。他以这些词开始这篇文章。。

Linux是基于Unix操作系统的，但也有许多独特而有用的内核特性和应用程序，这些特性和程序往往超出了Unix下可用的范围。一个鲜为人知的gem是“dialog”，这是一个用于从shell脚本中创建具有专业外观的对话框的实用工具。本文介绍了dialog实用程序的教程介绍，并展示了如何以及在何处使用它的示例

正如他所解释的，对话框是一个真正的宝石，使专业期待对话框轻松。它创建各种对话框、菜单、检查列表等。。它通常是默认安装的。如果没有，你可以从托马斯·迪基的网站上下载。

上面提到的文章很好地概述了它的用途和功能。手册页有更多详细信息。它可以在各种情况下使用。一个很好的例子是在文本模式下构建linux内核。Linux内核使用了一个根据需要定制的dialog的修改版本。

对话框最初设计用于shell脚本。如果您想在c程序中使用它的功能，那么可以使用libdialog。关于这一点的文件很少。最终参考是随库提供的dialog.h头文件。你可能需要在这里和那里黑客获得所需的输出。源代码很容易定制。我通过修改代码多次使用它。

### 19.3. Perl Curses模块Curses:：FORM和Curses:：WIDGETS
perl模块Curses、Curses：：Form和Curses：：Widgets提供了从perl访问Curses的权限。如果您有curses并且安装了basic perl，那么可以从CPAN所有模块页面获取这些模块。获取诅咒类中的三个压缩模块。一旦安装，您就可以像使用其他模块一样使用perl脚本中的这些模块。有关perl模块的更多信息，请参见perlmod手册页。上面的模块附带了很好的文档，并且有一些演示脚本来测试功能。尽管提供的小部件非常初级，但这些模块提供了从perl访问curses库的良好途径。

我的一些代码示例由Anuradha Ratnaweera转换为perl，它们可以在perl目录中找到。


有关更多信息，请参阅手册页Curses（3）、Curses:：Form（3）和Curses:：Widgets（3）。只有在获取并安装了上述模块之后，才能安装这些页面。

