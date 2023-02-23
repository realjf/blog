---
title: "NCURSES编程 之 18.表单库 18 Forms Library"
date: 2019-03-05T14:35:46+08:00
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

## 18 表单库
好。如果您在web页面上看到过这些表单，这些表单从用户那里获取输入并执行各种操作，您可能会想知道，任何人都会如何在文本模式显示中创建这样的表单。用平淡的语言写那些漂亮的表格是相当困难的。表单库试图提供一个基本的框架来轻松地构建和维护表单。它有很多特性（功能）来管理验证、字段的动态扩展等。。让我们看看它的全部流程。

表单是字段的集合；每个字段可以是标签（静态文本）或数据输入位置。表单库还提供了将表单划分为多个页面的函数。

### 18.1. 基础知识
表单的创建方式与菜单基本相同。首先，使用new_field（）创建与表单相关的字段。您可以为字段设置选项，以便它们可以显示一些奇特的属性，在字段失去焦点之前进行验证等。。然后字段被附加到窗体。在此之后，可以将表单发布到显示，并准备接收输入。在与menu_driver（）类似的行中，使用form_driver（）操作窗体。我们可以发送请求以形成驱动程序，将焦点移动到某个字段，将光标移动到字段的末尾等。。用户在字段中输入值并完成验证后，可以取消对窗体的过帐，并释放分配的内存。

窗体程序的一般控制流如下所示。

- 初始化curses
- 使用new_field（）创建字段。可以指定字段的高度和宽度及其在窗体上的位置。
- 通过指定要附加的字段，使用new_form（）创建表单。
- 使用form_Post（）发布表单并刷新屏幕。
- 使用循环处理用户请求，并使用表单驱动程序对表单进行必要的更新。
- 使用menu_Unpost（）取消菜单的粘贴
- 通过Free_form（）释放分配给菜单的内存
- 使用Free_field（）释放分配给项目的内存
- 结束curses

如您所见，使用表单库与处理菜单库非常相似。下面的例子将探讨表单处理的各个方面。让我们从一个简单的例子开始。第一。

### 18.2. 用表单库编译
要使用表单库函数，必须包含form.h，并且要将程序与表单库链接，标志-lform应按顺序与-lncurs一起添加。
```cpp
#include <form.h>
    .
    .
    .

    compile and link: gcc <program file> -lform -lncurses
```
表单示例
```cpp
#include <form.h>

int main()
{	FIELD *field[3];
	FORM  *my_form;
	int ch;

	/* Initialize curses */
	initscr();
	cbreak();
	noecho();
	keypad(stdscr, TRUE);

	/* Initialize the fields */
	field[0] = new_field(1, 10, 4, 18, 0, 0);
	field[1] = new_field(1, 10, 6, 18, 0, 0);
	field[2] = NULL;

	/* Set field options */
	set_field_back(field[0], A_UNDERLINE); 	/* Print a line for the option 	*/
	field_opts_off(field[0], O_AUTOSKIP);  	/* Don't go to next field when this */
						/* Field is filled up 		*/
	set_field_back(field[1], A_UNDERLINE);
	field_opts_off(field[1], O_AUTOSKIP);

	/* Create the form and post it */
	my_form = new_form(field);
	post_form(my_form);
	refresh();

	mvprintw(4, 10, "Value 1:");
	mvprintw(6, 10, "Value 2:");
	refresh();

	/* Loop through to get user requests */
	while((ch = getch()) != KEY_F(1))
	{	switch(ch)
		{	case KEY_DOWN:
				/* Go to next field */
				form_driver(my_form, REQ_NEXT_FIELD);
				/* Go to the end of the present buffer */
				/* Leaves nicely at the last character */
				form_driver(my_form, REQ_END_LINE);
				break;
			case KEY_UP:
				/* Go to previous field */
				form_driver(my_form, REQ_PREV_FIELD);
				form_driver(my_form, REQ_END_LINE);
				break;
			default:
				/* If this is a normal character, it gets */
				/* Printed				  */
				form_driver(my_form, ch);
				break;
		}
	}

	/* Un post form and free the memory */
	unpost_form(my_form);
	free_form(my_form);
	free_field(field[0]);
	free_field(field[1]);

	endwin();
	return 0;
}
```
上面的例子很直接。它用new_field（）创建两个字段。new_field（）获取高度、宽度、starty、startx、屏幕外行数和附加工作缓冲区数。第五个参数“屏幕外行数”指定要显示多少字段。如果为零，则始终显示整个字段，否则当用户访问字段中未显示的部分时，窗体将可滚动。表单库为每个字段分配一个缓冲区来存储用户输入的数据。使用new_field（）的最后一个参数，我们可以指定它来分配一些额外的缓冲区。这些可以用于任何你喜欢的用途。

创建字段后，这两个字段的back ground属性都用set_field_back（）设置为下划线。使用field_opts_off（）关闭AUTOSKIP选项。如果启用此选项，则在活动字段完全填满后，焦点将移到窗体中的下一个字段。

将字段附加到表单后，将发布该表单。在这里，用户输入在while循环中处理，通过发出相应的请求来形成驱动程序。对表单驱动程序（）的所有请求的详细信息将在后面解释。

### 18.3. 玩弄场地
每个表单字段都与许多属性相关联。他们可以被操纵，以获得所需的效果和乐趣！！！。为什么要等？
#### 18.3.1. 获取字段的大小和位置
我们在创建字段时提供的参数可以通过field_info（）检索。它在给定的参数中返回height、width、starty、startx、屏幕外行数和附加缓冲区数。它是new_field（）的一种逆形式。

```cpp
int field_info(     FIELD *field,              /* field from which to fetch */
                    int *height, *int width,   /* field size */
                    int *top, int *left,       /* upper left corner */
                    int *offscreen,            /* number of offscreen rows */
                    int *nbuf);                /* number of working buffers */
```
18.3.2. 移动场地
可以使用move_field（）将字段的位置移动到其他位置。
```cpp
int move_field(    FIELD *field,              /* field to alter */
                   int top, int left);        /* new upper-left corner */
```
与往常一样，可以使用field_infor（）查询更改的位置。

#### 18.3.3。字段对正
可以使用函数set_field_just（）修复要为字段做的对正。

```cpp
int set_field_just(FIELD *field,          /* field to alter */
               int justmode);         /* mode to set */
    int field_just(FIELD *field);          /* fetch justify mode of field */
```
这些函数接受并返回的对齐方式值为“NO_JUSTIFICATION”、“JUSTIFY_RIGHT”、“JUSTIFY_LEFT”或“JUSTIFY_CENTER”。

#### 18.3.4. 字段显示属性
如您所见，在上面的示例中，可以使用set_field_fore（）和set_field_back（）设置字段的display属性。这些函数设置字段的前景和背景属性。还可以指定填充字符，该字符将填充在字段的未填充部分。填充字符是通过调用set_field_pad（）来设置的。默认的填充值是空格。函数field_fore（）、field_back、field_pad（）可用于查询字段的当前前景、背景属性和填充字符。下表给出了函数的用法。
```cpp
int set_field_fore(FIELD *field,        /* field to alter */
                   chtype attr);        /* attribute to set */

chtype field_fore(FIELD *field);        /* field to query */
                                        /* returns foreground attribute */

int set_field_back(FIELD *field,        /* field to alter */
                   chtype attr);        /* attribute to set */

chtype field_back(FIELD *field);        /* field to query */
                                        /* returns background attribute */

int set_field_pad(FIELD *field,         /* field to alter */
                  int pad);             /* pad character to set */

chtype field_pad(FIELD *field);         /* field to query */
                                        /* returns present pad character */
```
虽然上面的函数看起来很简单，但在开始时使用set_field_fore（）的颜色可能会令人沮丧。首先让我解释一下字段的前景和背景属性。前景属性与角色相关联。这意味着字段中的字符将使用您使用set_field_fore（）设置的属性打印。背景属性是用于填充字段背景的属性，无论是否有字符。那么颜色呢？既然颜色总是成对定义的，那么显示彩色字段的正确方法是什么？下面是一个说明颜色属性的示例。

表单属性示例
```cpp
#include <form.h>

int main()
{	FIELD *field[3];
	FORM  *my_form;
	int ch;

	/* Initialize curses */
	initscr();
	start_color();
	cbreak();
	noecho();
	keypad(stdscr, TRUE);

	/* Initialize few color pairs */
	init_pair(1, COLOR_WHITE, COLOR_BLUE);
	init_pair(2, COLOR_WHITE, COLOR_BLUE);

	/* Initialize the fields */
	field[0] = new_field(1, 10, 4, 18, 0, 0);
	field[1] = new_field(1, 10, 6, 18, 0, 0);
	field[2] = NULL;

	/* Set field options */
	set_field_fore(field[0], COLOR_PAIR(1));/* Put the field with blue background */
	set_field_back(field[0], COLOR_PAIR(2));/* and white foreground (characters */
						/* are printed in white 	*/
	field_opts_off(field[0], O_AUTOSKIP);  	/* Don't go to next field when this */
						/* Field is filled up 		*/
	set_field_back(field[1], A_UNDERLINE);
	field_opts_off(field[1], O_AUTOSKIP);

	/* Create the form and post it */
	my_form = new_form(field);
	post_form(my_form);
	refresh();

	set_current_field(my_form, field[0]); /* Set focus to the colored field */
	mvprintw(4, 10, "Value 1:");
	mvprintw(6, 10, "Value 2:");
	mvprintw(LINES - 2, 0, "Use UP, DOWN arrow keys to switch between fields");
	refresh();

	/* Loop through to get user requests */
	while((ch = getch()) != KEY_F(1))
	{	switch(ch)
		{	case KEY_DOWN:
				/* Go to next field */
				form_driver(my_form, REQ_NEXT_FIELD);
				/* Go to the end of the present buffer */
				/* Leaves nicely at the last character */
				form_driver(my_form, REQ_END_LINE);
				break;
			case KEY_UP:
				/* Go to previous field */
				form_driver(my_form, REQ_PREV_FIELD);
				form_driver(my_form, REQ_END_LINE);
				break;
			default:
				/* If this is a normal character, it gets */
				/* Printed				  */
				form_driver(my_form, ch);
				break;
		}
	}

	/* Un post form and free the memory */
	unpost_form(my_form);
	free_form(my_form);
	free_field(field[0]);
	free_field(field[1]);

	endwin();
	return 0;
}
```
播放颜色对，并尝试了解前景和背景属性。在使用颜色属性的程序中，我通常只设置背景，设置为set_field_back（）。诅咒根本不允许定义单个颜色属性。

#### 18.3.5。字段选项位
还有一个大的字段选项位集合，您可以设置为控制表单处理的各个方面。可以使用以下函数操作它们：
```cpp
int set_field_opts(FIELD *field,          /* field to alter */
                   int attr);             /* attribute to set */

int field_opts_on(FIELD *field,           /* field to alter */
                  int attr);              /* attributes to turn on */

int field_opts_off(FIELD *field,          /* field to alter */
                  int attr);              /* attributes to turn off */

int field_opts(FIELD *field);             /* field to query */
```

函数set_field_opts（）可以用来直接设置字段的属性，也可以选择使用field_opts_on（）和field_opts_off（）来打开和关闭一些属性。任何时候都可以使用field_opts（）查询字段的属性。以下是可用选项的列表。默认情况下，所有选项都处于启用状态。

- O_VISIBLE
控制字段在屏幕上是否可见。可以在表单处理过程中根据父字段的值隐藏或弹出字段。
- O_ACTIVE
控制该字段在表单处理期间是否处于活动状态（即通过表单导航键访问）。可用于使具有缓冲区值的标签或派生字段可由窗体应用程序而不是用户更改。
- O_PUBLIC
控制字段输入期间是否显示数据。如果在某个字段上禁用此选项，则库将接受并编辑该字段中的数据，但不会显示该字段，并且可见字段光标也不会移动。您可以关闭O\ U公共位来定义密码字段。
- O_EDIT
控制是否可以修改字段的数据。当此选项关闭时，除REQ_PREV_CHOICE 和REQ_NEXT_CHOICE外的所有编辑请求都将失败。此类只读字段可能对帮助消息有用。
- O_WRAP
控制多行字段中的换行。通常，当一个（空格分隔的）单词的任何字符到达当前行的末尾时，整个单词将被包装到下一行（假设有一个）。禁用此选项时，单词将被拆分为两个换行符。
- O_BLANK
控制字段消隐。启用此选项时，在第一个字段位置输入字符将删除整个字段（除了刚输入的字符）。
- O_AUTOSKIP
控制此字段填充时自动跳到下一个字段。通常情况下，当表单用户试图在一个字段中键入超出其容量的数据时，编辑位置会跳转到下一个字段。禁用此选项时，用户的光标将挂在字段的末尾。在未达到大小限制的动态字段中忽略此选项。
- O_NULLOK
控制是否对空白字段应用验证。通常情况下，不是这样；用户可以将字段留空，而无需在退出时调用通常的验证检查。如果在字段上禁用此选项，则退出该选项将调用验证检查。
- O_PASSOK
控制是在每次退出时进行验证，还是仅在修改字段后进行验证。通常后者是正确的。如果您的字段的验证函数在表单处理过程中可能发生更改，则设置O_PASSOK 可能很有用。
- O_STATIC
控制字段是否固定为其初始尺寸。如果关闭此选项，字段将变为动态字段，并将拉伸以适合输入的数据。

当前选定字段时，无法更改该字段的选项。但是，非当前的已过帐字段上的选项可能会更改。
选项值是位掩码，可以用逻辑或明显的方式组成。您已经看到了关闭O_AUTOSKIP 选项的用法。下面的示例说明了其他一些选项的用法。在适当的情况下解释其他选项。

```cpp
#include <form.h>

#define STARTX 15
#define STARTY 4
#define WIDTH 25

#define N_FIELDS 3

int main()
{	FIELD *field[N_FIELDS];
	FORM  *my_form;
	int ch, i;

	/* Initialize curses */
	initscr();
	cbreak();
	noecho();
	keypad(stdscr, TRUE);

	/* Initialize the fields */
	for(i = 0; i < N_FIELDS - 1; ++i)
		field[i] = new_field(1, WIDTH, STARTY + i * 2, STARTX, 0, 0);
	field[N_FIELDS - 1] = NULL;

	/* Set field options */
	set_field_back(field[1], A_UNDERLINE); 	/* Print a line for the option 	*/

	field_opts_off(field[0], O_ACTIVE); /* This field is a static label */
	field_opts_off(field[1], O_PUBLIC); /* This filed is like a password field*/
	field_opts_off(field[1], O_AUTOSKIP); /* To avoid entering the same field */
					      /* after last character is entered */

	/* Create the form and post it */
	my_form = new_form(field);
	post_form(my_form);
	refresh();

	set_field_just(field[0], JUSTIFY_CENTER); /* Center Justification */
	set_field_buffer(field[0], 0, "This is a static Field");
						  /* Initialize the field  */
	mvprintw(STARTY, STARTX - 10, "Field 1:");
	mvprintw(STARTY + 2, STARTX - 10, "Field 2:");
	refresh();

	/* Loop through to get user requests */
	while((ch = getch()) != KEY_F(1))
	{	switch(ch)
		{	case KEY_DOWN:
				/* Go to next field */
				form_driver(my_form, REQ_NEXT_FIELD);
				/* Go to the end of the present buffer */
				/* Leaves nicely at the last character */
				form_driver(my_form, REQ_END_LINE);
				break;
			case KEY_UP:
				/* Go to previous field */
				form_driver(my_form, REQ_PREV_FIELD);
				form_driver(my_form, REQ_END_LINE);
				break;
			default:
				/* If this is a normal character, it gets */
				/* Printed				  */
				form_driver(my_form, ch);
				break;
		}
	}

	/* Un post form and free the memory */
	unpost_form(my_form);
	free_form(my_form);
	free_field(field[0]);
	free_field(field[1]);

	endwin();
	return 0;
}
```
这个示例虽然没有用，但显示了选项的用法。如果使用得当，它们可以以一种形式非常有效地呈现信息。第二个字段不是O_PUBLIC，它不显示您正在键入的字符。

#### 18.3.6。字段状态
字段状态指定字段是否已编辑。它最初设置为FALSE，当用户输入某个东西并修改数据缓冲区时，它将变为TRUE。因此，可以查询字段的状态，以确定字段是否已修改。以下功能可帮助这些操作。

```cpp
int set_field_status(FIELD *field,      /* field to alter */
                   int status);         /* status to set */

int field_status(FIELD *field);         /* fetch status of field */
```
最好在离开字段之后才检查字段的状态，因为数据缓冲区可能还没有更新，因为验证仍然到期。为了保证返回正确的状态，可以（1）在字段的exit validation check例程中，（2）从字段或窗体的初始化或终止挂钩调用field_status（），或者（3）在窗体驱动程序处理REQ_VALIDATION请求之后调用field_status（）

#### 18.3.7. 字段用户指针
每个字段结构都包含一个指针，用户可以将其用于各种目的。表单库不触及它，用户可以将其用于任何目的。下面的函数设置并获取用户指针。

```cpp
int set_field_userptr(FIELD *field,
           char *userptr);      /* the user pointer you wish to associate */
                                /* with the field    */

char *field_userptr(FIELD *field);      /* fetch user pointer of the field */
```
#### 18.3.8。可变大小字段
如果您想要一个动态变化的可变宽度字段，这是您想要充分使用的功能。这将允许用户输入超过字段原始大小的数据，并允许字段增长。根据字段方向，它将水平或垂直滚动以合并新数据。
要使字段动态可扩展，应关闭选项O_STATIC 。这可以用

```cpp
field_opts_off(field_pointer, O_STATIC);
```
但通常不建议让一个领域无限增长。您可以使用设置字段增长的最大限制

```cpp
int set_max_field(FIELD *field,    /* Field on which to operate */
                  int max_growth); /* maximum growth allowed for the field */
```
动态可增长字段的字段信息可通过以下方式检索
```cpp
int dynamic_field_info( FIELD *field,     /* Field on which to operate */
            int   *prows,     /* number of rows will be filled in this */
            int   *pcols,     /* number of columns will be filled in this*/
            int   *pmax)      /* maximum allowable growth will be filled */
                              /* in this */

```
虽然field_info与往常一样工作，但最好使用此函数来获得动态可增长字段的适当属性。

回忆库例程new_field；将定义为一个高度设置为一个的新字段为单行字段。将定义高度大于一个的新字段为多行字段。

一个O_STATIC 关闭（动态可扩展字段）的单行字段将包含一个固定行，但如果用户输入的数据多于初始字段所保留的数据，则列数会增加。显示的列数将保持不变，附加数据将水平滚动。

关闭O_STATIC（动态可扩展字段）的多行字段将包含固定数量的列，但如果用户输入的数据多于初始字段所保留的数据，则行数会增加。显示的行数将保持不变，附加数据将垂直滚动。

以上两段几乎描述了动态增长场的行为。表单库的其他部分的行为方式如下所述：

- 如果选项O_STATIC为off，并且没有为该字段指定最大增长，则将忽略字段选项O_AUTOSKIP 。目前，当用户在字段的最后一个字符位置键入时，O_AUTOSKIP 生成自动REQ_NEXT_FIELD表单驱动程序请求。在没有指定最大生长量的可生长字段上，没有最后一个字符位置。如果指定了最大增长，如果字段已扩展到最大大小，则O_AUTOSKIP 选项将正常工作。

- 如果选项O_STATIC为off，则将忽略字段对正。目前，set_field_just 仅可用于JUSTIFY_LEFT、JUSTIFY_RIGHT、JUSTIFY_CENTER 单行字段的内容。一个可增长的单行字段，根据定义，将水平增长和滚动，并且可能包含的数据超出了合理的范围。field_just 的返回将保持不变。

- 如果字段选项O_STATIC为off，并且没有为字段指定最大增长，重载表单驱动程序请求REQ_NEW_LINE 将以相同的方式运行，而不考虑O_NL_OVERLOAD form选项。当前，如果窗体选项O_NL_OVERLOAD 处于on状态，则REQ_NEW_LINE 隐式地生成REQ_NEXT_FIELD 字段，如果从字段的最后一行调用。如果字段可以无绑定地增长，则没有最后一行，因此REQ_NEW_LINE 将永远不会隐式地生成REQ_NEXT_FIELD。如果指定了最大增长限制，并且O_NL_OVERLOAD  form选项处于on状态，则REQ_NEW_LINE仅在字段已扩展到最大大小且用户处于最后一行时，才会隐式生成REQ_NEXT_FIELD 字段。

- 库调用dup_field 将一如既往地工作；它将复制该字段，包括当前缓冲区大小和要复制的字段的内容。任何指定的最大增长也将重复。

- 库调用link_field 将一如既往地工作；它将复制所有字段属性，并与链接的字段共享缓冲区。如果O_STATIC 字段选项随后由字段共享缓冲区更改，系统对尝试在字段中输入的数据的反应如何，而当前缓冲区将保留的数据将取决于当前字段中选项的设置。

- 库调用field_info将一如既往地工作；变量 nrow 将包含原始调用new_field的值。用户应该使用上面描述的dynamic_field_info查询缓冲区的当前大小。

以上几点只有在解释表单驱动程序后才有意义。我们将在接下来的几个部分中研究这个问题。

### 18.4. 窗体窗口
窗体windows概念与菜单窗口非常相似。每个表单都与主窗口和子窗口关联。窗体主窗口显示任何与之关联的标题或边框，或用户希望的任何内容。然后子窗口包含所有字段，并根据字段的位置显示它们。这使得操纵花哨的形式显示非常容易。

由于这与菜单窗口非常相似，所以我提供了一个例子，给出了很多解释。这些函数是相似的，它们的工作方式相同。

```cpp
#include <form.h>

void print_in_middle(WINDOW *win, int starty, int startx, int width, char *string, chtype color);

int main()
{
	FIELD *field[3];
	FORM  *my_form;
	WINDOW *my_form_win;
	int ch, rows, cols;

	/* Initialize curses */
	initscr();
	start_color();
	cbreak();
	noecho();
	keypad(stdscr, TRUE);

	/* Initialize few color pairs */
   	init_pair(1, COLOR_RED, COLOR_BLACK);

	/* Initialize the fields */
	field[0] = new_field(1, 10, 6, 1, 0, 0);
	field[1] = new_field(1, 10, 8, 1, 0, 0);
	field[2] = NULL;

	/* Set field options */
	set_field_back(field[0], A_UNDERLINE);
	field_opts_off(field[0], O_AUTOSKIP); /* Don't go to next field when this */
					      /* Field is filled up 		*/
	set_field_back(field[1], A_UNDERLINE);
	field_opts_off(field[1], O_AUTOSKIP);

	/* Create the form and post it */
	my_form = new_form(field);

	/* Calculate the area required for the form */
	scale_form(my_form, &rows, &cols);

	/* Create the window to be associated with the form */
        my_form_win = newwin(rows + 4, cols + 4, 4, 4);
        keypad(my_form_win, TRUE);

	/* Set main window and sub window */
        set_form_win(my_form, my_form_win);
        set_form_sub(my_form, derwin(my_form_win, rows, cols, 2, 2));

	/* Print a border around the main window and print a title */
        box(my_form_win, 0, 0);
	print_in_middle(my_form_win, 1, 0, cols + 4, "My Form", COLOR_PAIR(1));

	post_form(my_form);
	wrefresh(my_form_win);

	mvprintw(LINES - 2, 0, "Use UP, DOWN arrow keys to switch between fields");
	refresh();

	/* Loop through to get user requests */
	while((ch = wgetch(my_form_win)) != KEY_F(1))
	{	switch(ch)
		{	case KEY_DOWN:
				/* Go to next field */
				form_driver(my_form, REQ_NEXT_FIELD);
				/* Go to the end of the present buffer */
				/* Leaves nicely at the last character */
				form_driver(my_form, REQ_END_LINE);
				break;
			case KEY_UP:
				/* Go to previous field */
				form_driver(my_form, REQ_PREV_FIELD);
				form_driver(my_form, REQ_END_LINE);
				break;
			default:
				/* If this is a normal character, it gets */
				/* Printed				  */
				form_driver(my_form, ch);
				break;
		}
	}

	/* Un post form and free the memory */
	unpost_form(my_form);
	free_form(my_form);
	free_field(field[0]);
	free_field(field[1]);

	endwin();
	return 0;
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
### 18.5. 现场验证
默认情况下，字段将接受用户输入的任何数据。可以将验证附加到字段。然后，当该字段包含与验证类型不匹配的数据时，用户离开该字段的任何尝试都将失败。某些验证类型还具有每次在字段中输入字符时的字符有效性检查。

验证可以附加到具有以下功能的字段。
```cpp
int set_field_type(FIELD *field,          /* field to alter */
                   FIELDTYPE *ftype,      /* type to associate */
                   ...);                  /* additional arguments*/
```
设置后，可以使用查询字段的验证类型
```cpp
FIELDTYPE *field_type(FIELD *field);      /* field to query */
```
表单驱动程序仅在最终用户输入数据时验证字段中的数据。在以下情况下不会进行验证：
- 应用程序通过调用set_field_buffer来更改字段值。
- 链接的字段值是间接更改的--通过更改它们链接到的字段

以下是预定义的验证类型。您还可以指定自定义验证，尽管这有点棘手和麻烦。

#### TYPE_ALPHA
此字段类型接受字母数据；无空格、无数字、无特殊字符（在字符输入时检查）。其设置如下：
```cpp
int set_field_type(FIELD *field,          /* field to alter */
                   TYPE_ALPHA,            /* type to associate */
                   int width);            /* maximum width of field */
```
width参数设置数据的最小宽度。用户必须输入至少个字符才能离开该字段。通常，您需要将其设置为字段宽度；如果它大于字段宽度，验证检查将始终失败。最小宽度为零表示字段完成是可选的。
#### TYPE_ALNUM
此字段类型接受字母数据和数字；没有空格，没有特殊字符（在字符输入时检查）。其设置如下：
```cpp
int set_field_type(FIELD *field,          /* field to alter */
                   TYPE_ALNUM,            /* type to associate */
                   int width);            /* maximum width of field */
```
width参数设置数据的最小宽度。与TYPE_ALPHA一样，通常需要将其设置为字段宽度；如果它大于字段宽度，验证检查将始终失败。最小宽度为零表示字段完成是可选的。
#### TYPE_ENUM
此类型允许您将字段的值限制为一组指定的字符串值（例如，美国各州的两个字母的邮政编码）。其设置如下：
```cpp
int set_field_type(FIELD *field,          /* field to alter */
                   TYPE_ENUM,             /* type to associate */
                   char **valuelist;      /* list of possible values */
                   int checkcase;         /* case-sensitive? */
                   int checkunique);      /* must specify uniquely? */
```
valuelist参数必须指向以NULL结尾的有效字符串列表。checkcase参数如果为true，则与区分大小写的字符串进行比较。

当用户退出类型枚举字段时，验证过程将尝试将缓冲区中的数据完成为有效条目。如果输入了一个完整的选项字符串，它当然是有效的。但也可以输入一个有效字符串的前缀，并为您完成它。

默认情况下，如果您输入这样一个前缀，并且它与字符串列表中的多个值匹配，则前缀将完成为第一个匹配的值。但是checkunique参数如果为true，则需要前缀匹配项唯一才能有效。

REQ_NEXT_CHOICE 和REQ_PREV_CHOICE 输入请求对于这些字段特别有用。

#### TYPE_INTEGER
此字段类型接受整数。其设置如下：
```cpp
int set_field_type(FIELD *field,          /* field to alter */
                   TYPE_INTEGER,          /* type to associate */
                   int padding,           /* # places to zero-pad to */
                   int vmin, int vmax);   /* valid range */
```
有效字符由可选的前导和减号组成。退出时执行范围检查。如果范围最大值小于或等于最小值，则忽略范围。

如果值通过其范围检查，则会根据需要使用尽可能多的前导零位来填充该值，以满足padding参数的要求。

用C库函数atoi（3）可以很方便地解释一个TYPE_INTEGER缓冲区。
#### TYPE_NUMERIC

此字段类型接受十进制数。其设置如下：
```cpp
int set_field_type(FIELD *field,          /* field to alter */
                   TYPE_NUMERIC,          /* type to associate */
                   int padding,           /* # places of precision */
                   int vmin, int vmax);   /* valid range */
```
有效字符由可选的前导和减号组成。可能包括小数点。退出时执行范围检查。如果范围最大值小于或等于最小值，则忽略范围。

如果值通过其范围检查，则会根据需要使用尽可能多的尾随零位来填充该值，以满足padding参数的要求。

用C库函数atof（3）可以方便地解释一个TYPE_NUMERIC缓冲区。
#### TYPE_REGEXP
此字段类型接受与正则表达式匹配的数据。其设置如下：

```cpp
int set_field_type(FIELD *field,          /* field to alter */
                   TYPE_REGEXP,           /* type to associate */
                   char *regexp);         /* expression to match */
```
正则表达式的语法是regcomp（3）的语法。在退出时执行正则表达式匹配检查。

### 18.6 表单驱动程序：表单系统的工作马
与菜单系统一样，表单驱动程序（）在表单系统中起着非常重要的作用。对表单系统的所有类型的请求都应该通过form_driver（）导入。
```cpp
int form_driver(FORM *form,     /* form on which to operate     */
                int request)    /* form request code         */
```
正如上面的一些示例所示，您必须在一个循环中查找用户输入，然后确定它是字段数据还是表单请求。然后，表单请求被传递到form_driver（）来完成这项工作。

这些请求大致可分为以下几类。不同的请求及其用法解释如下：

#### 18.6.1 页面导航请求
这些请求导致页面级别在表单中移动，从而触发新表单屏幕的显示。表单可以由多页组成。如果您有一个包含许多字段和逻辑部分的大表单，那么您可以将表单划分为多个页面。函数set_new_page（）可在指定字段设置新页。
```cpp
int set_new_page(FIELD *field,/* Field at which page break to be set or unset */
         bool new_page_flag); /* should be TRUE to put a break */
```
以下请求允许您移动到不同的页面
- REQ_NEXT_PAGE移动到下一个表单页。
- REQ_PREV_PAGE 移动到上一个表单页。
- REQ_FIRST_PAGE 移动到第一个表单页。
- REQ_LAST_PAGE 移动到最后一个表单页。

这些请求将列表视为循环的；也就是说，从最后一页的REQ_NEXT_PAGE 转到第一个，而第一页的REQ_PREV_PAGE 将转到最后一页。

#### 18.6.2 现场导航请求
这些请求处理同一页上字段之间的导航。
- REQ_NEXT_FIELD 移动到下一个字段。
- REQ_PREV_FIELD 移至上一个字段。
- REQ_FIRST_FIELD 移动到第一个字段。
- REQ_LAST_FIELD 移动到最后一个字段。
- REQ_SNEXT_FIELD 移动到排序的下一个字段。
- REQ_SPREV_FIELD 移动到排序的上一个字段。
- REQ_SFIRST_FIELD 移动到排序的第一个字段。
- REQ_SLAST_FIELD 移动到排序的最后一个字段。
- REQ_LEFT_FIELD 向左移动到字段。
- REQ_RIGHT_FIELD 向右移动到字段。
- REQ_UP_FIELD 向上移动到字段。
- REQ_DOWN_FIELD向下移动到字段。

这些请求将页面上的字段列表视为循环的；也就是说，从最后一个字段中的REQ_NEXT_FIELD转到第一个字段，而第一个字段的REQ_PREV_FIELD将转到最后一个字段。这些字段的顺序（以及RREQ_FIRST_FIELD和REQ_LAST_FIELD请求）只是表单数组中字段指针的顺序（由new_form（）设置或set_form_fields（）

也可以像按屏幕位置顺序排序一样遍历字段，因此顺序从左到右，从上到下。为此，请使用第二组四个排序的移动请求。

最后，可以使用视觉方向上、下、右和左在字段之间移动。要完成这一点，请使用第三组四个请求。但是，请注意，用于这些请求的表单的位置是其左上角。

例如，假设您有一个多行字段B，两个单线字段a和C与B在同一行上，B左侧为a，C的右侧为a。a REQ_MOVE_RIGHT 仅当a、B和C都共享同一行时，才将从a向右移动到B；否则将跳过B到C。

#### 18.6.3 字段内导航请求
这些请求驱动当前选定字段中编辑光标的移动。

- REQ_NEXT_CHAR 移动到下一个字符。
- REQ_PREV_CHAR 移动到上一个字符。
- REQ_NEXT_LINE 移动到下一行。
- REQ_PREV_LINE 移至上一行。
- REQ_NEXT_WORD 移动到下一个单词。
- REQ_PREV_WORD 移至上一个单词。
- REQ_BEG_FIELD 移动到字段的开始。
- REQ_END_FIELD 移动到字段的末尾。
- REQ_BEG_LINE 移动到行的开始。
- REQ_END_LINE 移动到行的结尾。
- REQ_LEFT_CHAR 在字段中向向左的字符。
- REQ_RIGHT_CHAR 在字段中向右移动。
- REQ_UP_CHAR 向上移动字段中的字符。
- REQ_DOWN_CHAR 向下移动字段中的字符。

每个单词都用空格与前面和下一个字符分隔。移动到行或字段的开始和结束的命令在其范围内查找第一个或最后一个非pad字符。

#### 18.6.4 滚动请求
动态的、已增长的字段以及用屏幕外行显式创建的字段都可以滚动。单行字段水平滚动；多行字段垂直滚动。大多数滚动是通过编辑和字段内移动触发的（库滚动字段以保持光标可见）。可以显式请求滚动，并具有以下请求：

- REQ_SCR_FLINE 垂直向前滚动一行。
- REQ_SCR_BLINE 垂直向后滚动一行。
- REQ_SCR_FPAGE 垂直向前滚动一页。
- REQ_SCR_BPAGE 页面垂直向后滚动。
- REQ_SCR_FHPAGE 垂直向前滚动半页。
- REQ_SCR_BHPAGE 垂直向后滚动半页。
- REQ_SCR_FCHAR 水平向前滚动一个字符。
- REQ_SCR_BCHAR 水平向后滚动一个字符。
- REQ_SCR_HFLINE 水平滚动一个字段宽度向前。
- REQ_SCR_HBLINE 水平滚动一个字段宽度向后滚动。
- REQ_SCR_HFHALF 水平滚动一个半字段宽度向前。
- REQ_SCR_HBHALF 水平滚动一个半字段宽度向后滚动。

为了滚动目的，字段的页面是其可见部分的高度。

#### 18.6.5. 编辑请求
当您向表单驱动程序传递一个ASCII字符时，它将被视为向字段的数据缓冲区中添加该字符的请求。这是插入还是替换取决于字段的编辑模式（默认为插入）。

以下请求支持编辑字段和更改编辑模式：

- REQ_INS_MODE 设置插入模式。
- REQ_OVL_MODE 设置覆盖模式。
- REQ_NEW_LINE 新行请求（请参阅下面的说明）。
- REQ_INS_CHAR 在字符位置插入空格。
- REQ_INS_LINE 在字符位置插入空行。
- REQ_DEL_CHAR 删除光标处的字符。
- REQ_DEL_PREV 删除光标处的上一个单词。
- REQ_DEL_LINE 删除光标处的行。
- REQ_DEL_WORD 删除字在光标处删除字。
- REQ_CLR_EOL 清除下线。
- REQ_CLR_EOF 清除字段末尾。
- REQ_CLR_FIELD 清除字段清除整个字段。

REQ_NEW_LINE 和REQ_DEL_PREV 请求的行为很复杂，部分由一对表单选项控制。当光标位于字段开头或字段的最后一行时，将触发特殊情况。

首先，我们考虑REQ_NEW_LINE ：

在插入模式下，REQ_NEW_LINE 的正常行为是在编辑光标的位置打断当前行，将光标后面的当前行部分插入为当前行之后的新行，并将光标移动到新行的开头（您可能认为这是在字段缓冲区中插入新行）。

在覆盖模式下，REQ_NEW_LINE 的正常行为是将当前行从编辑光标的位置清除到行尾。然后将光标移到下一行的开头。

但是，在字段开头或字段最后一行的REQ_NEW_LINE 会执行REQ_NEXT_FIELD。O_NL_OVERLOAD 处于关闭状态，则此特殊操作将被禁用。

现在，让我们考虑一下REQ_DEL_PREV：

REQ_DEL_PREV的正常行为是删除前一个字符。如果“插入”模式处于启用状态，并且光标位于行的开头，并且该行上的文本将与前一行匹配，则它会将当前行的内容附加到前一行，并删除当前行（您可能认为这是从字段缓冲区中删除新行）。

但是，字段开头的REQ_DEL_PREV被视为REQ_PREV_FIELD。

如果O_BS_OVERLOAD 选项处于关闭状态，则此特殊操作将被禁用，窗体驱动程序只返回E_REQUEST_DENIED。

#### 18.6.6. 订单请求
如果字段的类型是有序的，并且具有用于从给定值获取该类型的下一个值和上一个值的关联函数，则存在可以将该值提取到字段缓冲区的请求：

- REQ_NEXT_CHOICE 将当前值的后继值放入缓冲区。
- REQ_PREV_CHOICE 将当前值的前置值放入缓冲区。

在内置字段类型中，只有类型\u ENUM具有内置的后续函数和前置函数。定义自己的字段类型（请参见自定义验证类型）时，可以关联我们自己的排序函数。

#### 18.6.7. 应用程序命令
表单请求表示为大于KEY_MAX 且小于或等于常量MAX_COMMAND的curses值以上的整数。此范围内的值将被form_driver（）忽略。因此应用程序可以将其用于任何目的。可以将其视为特定于应用程序的操作并采取相应的操作


