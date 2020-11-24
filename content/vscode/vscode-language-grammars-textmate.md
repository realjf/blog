---
title: "VS Code语言语法分词引擎 TextMate语法解析 (Vscode Language Grammars Engine - TextMate)"
date: 2020-11-24T15:44:23+08:00
keywords: ["vscode"]
categories: ["vscode"]
tags: ["vscode"]
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

语言语法用于为文档元素（如关键字、注释、字符串或类似内容）指定名称。
这样做的目的是允许设置样式（语法高亮显示），并使文本编辑器“智能”地了解插入符号所在的上下文。
例如，您可能希望按键或制表符触发器根据上下文的不同而采取不同的操作，
或者您可能希望在键入文本文档中不是散文的部分（例如HTML标记）时禁用拼写检查。

语言语法仅用于分析文档并为该文档的子集分配名称。然后，范围选择器可以用于样式设置、
首选项以及决定键和选项卡触发器应该如何展开。

有关这个概念的更全面的介绍，请参阅[scopes简介](https://macromates.com/blog/2005/introduction-to-scopes/)博客文章

## 语法示例

先来看下以下示例
```textmate
{
	scopeName = 'source.untitled';
	fileTypes = ();
	foldingStartMarker = '\{\s*$';
	foldingStopMarker = '^\s*\}';
	patterns = ({
		name = 'keyword.control.untitled';
		match = '\b(if|while|for|return)\b';

	}, {
		name = 'string.quoted.double.untitled';
		begin = '"';
		end = '"';
		patterns = ({
			name = 'constant.character.escape.untitled';
			match = '\\.';

		});
	},
 );
}
```
格式是[属性列表格式](https://macromates.com/manual/en/appendix#property-list-format)，在根级别有五个键/值对：

- scopeName(第1行)：这应该是语法的唯一名称，遵循一个点分隔名称的惯例，
其中每个新的（最左边的）部分专门指定名称。通常它是由两部分组成的名称，第一部分是text或source，
第二部分是语言或文档类型的名称。但是，如果要专门化一个现有类型，则可能需要从所专门化的类型派生名称。
例如，Markdown是text.html.markdown而ruby on rails（rhtml文件）则是text.html.rails. 
从（在这种情况下）得到它的好处，text.html这就是在text.html域也将在text.html.«something»域（但优先级低于特定目标text.html.«something»）。

- fileTypes(第2行)：这是一个文件类型扩展名的数组，语法应该（默认情况下）与之一起使用。
当TextMate不知道用户打开的文件要使用什么语法时，就会引用它。但是，如果用户在TextMate的状态栏中选择了一个语法选项，
那么TextMate就会记住用户选择。

- foldingStartMarker/foldingStopMarker(第3-4行)：这些是（文档中）行匹配的正则表达式。
如果一行匹配其中一个模式（但不是两个模式），它将成为折叠标记（有关更多信息，请参阅[foldings](https://macromates.com/manual/en/navigation_overview#customizing-foldings)部分）。

- patterns(第5-18行)：这是一个数组，其中包含用于解析文档的实际规则。
在这个例子中有两个规则（第6-8行和第9-17行）。规则将在下一节中解释。

示例中没有使用两个附加（根级）键：

- firstLineMatch：与文档第一行匹配的正则表达式（当它第一次加载时）。如果匹配，则语法将用于文档（除非有用户覆盖）。
示例：^#!/.*\bruby\b。

- repository：一种包含规则的字典（即键/值对），它可以从语法中的其他地方包括进来。
键是规则的名称，值是实际的规则。在后面描述的include rule key中有进一步的解释（和示例）。

## 语言规则

语言规则负责匹配文档的一部分。通常，规则会指定一个名称，该名称分配给与该规则匹配的文档部分。

规则可以通过两种方式匹配文档。它可以提供一个正则表达式，也可以提供两个。
与上面第一个规则（第6-8行）中的match键一样，匹配该正则表达式的所有内容都将获得该规则指定的名称。
例如，上面的第一个规则指定名称keyword.control.untitled对以下关键字：
if、while、for和return。然后我们可以使用范围选择器keyword.control让这些关键字有我们的主题风格。

另一种类型的匹配是第二条规则使用的匹配（第9-17行）。这里使用begin和end键给出了两个正则表达式。
规则的名称将从开始模式匹配的位置分配到结束模式匹配的位置（包括两个匹配项）。
如果没有匹配的结束模式，则使用文档的结尾。

在后一种形式中，规则可以包含子规则，这些子规则与开始匹配和结束匹配之间的部分匹配。
在我们的示例中，我们匹配以引号字符开头和结尾的字符串，在匹配字符串中（第13-15行），
转义字符标记为constant.character.escape.untitled。


注意，正则表达式一次只与文档的一行匹配。这意味着不可能使用匹配多行的模式。
这样做的原因是技术性的：能够在任意行重新启动解析器，并且只需要重新解析受编辑影响的最小行数。
在大多数情况下，可以使用begin/end模型来克服这个限制。


## Rule Keys
以下关键字被用于一条规则中：

- name：分配给匹配部分的名称。这用于设置样式和范围特定的设置和操作，这意味着它通常应该从一个标准名称派生（请参见后面的命名约定）。

- match：一种正则表达式，用于标识应将名称分配给的文本部分。示例：'\b(true|false)\b'

- begin,end：这些键允许跨越多行的匹配，并且必须与match键互斥。每个都是正则表达式模式。
begin是启动块的模式，end是结束块的模式。通过使用普通正则表达式反向引用，
可以在结束模式中引用来自开始模式的捕获。这通常与here-docs一起使用，例如：
```textmate
{   name = 'string.unquoted.here-doc';
     begin = '<<(\w+)';  // match here-doc token
     end = '^\1$';       // match end of here-doc
 }
```
begin/end规则可以使用patterns键来嵌套模式。例如，我们可以：
```textmate
{  begin = '<%'; end = '%>'; patterns = (
       { match = '\b(def|end)\b'; … },
       …
    );
 };
```
上面的代码将匹配<%…%>块中的def和end关键字（不过对于嵌入式语言，请参见后面关于include键的信息）。

- contentName：此键类似于name键，但只将名称指定给与begin/end模式匹配的文本。例如，
要将#if 0和#endif之间的文本标记为注释，我们可以这样做
```textmate
{  begin = '#if 0(\s.*)?$'; end = '#endif';
    contentName = 'comment.block.preprocessor';
 };
```

- captures,beginCaptures,endCaptures：这些键允许您为match、begin或end模式的捕获分配属性。
在begin/end规则中使用captures键是为beginCaptures和endCaptures提供相同值的简写方法。

这些键的值是一个字典，键是捕获号，值是分配给捕获文本的属性字典。当前只支持name属性。下面是一个例子：
```textmate
{  match = '(@selector\()(.*?)(\))';
    captures = {
       1 = { name = 'storage.type.objc'; };
       3 = { name = 'storage.type.objc'; };
    };
 };
```
在这个例子中，我们匹配 @selector(windowWillClose:) 这样的文本，但是 storage.type.objc 名称将仅分配给 @selector( 和 )。


- include：这允许您引用其他语言，递归地引用语法本身或此文件存储库中声明的规则。

    - 1.为了引用其他语言，使用语言的域名称：
```textmate
{  begin = '<\?(php|=)?'; end = '\?>'; patterns = (
       { include = "source.php"; }
    );
 }
```
    - 2. 为其引用语法，使用$self
```textmate
{  begin = '\('; end = '\)'; patterns = (
       { include = "$self"; }
    );
 }
```

    - 3. 从当前的语法仓库中引用一个规则，在名称前面加一个井号（#）
```textmate
patterns = (
    {  begin = '"'; end = '"'; patterns = (
          { include = "#escaped-char"; },
          { include = "#variable"; }
       );
    },
    …
 ); // end of patterns
 repository = {
    escaped-char = { match = '\\.'; };
    variable =     { match = '\$[a-zA-Z0-9_]+'; };
 };
```
    这也能被用于递归匹配结构
```textmate
patterns = (
    {  name = 'string.unquoted.qq.perl';
       begin = 'qq\('; end = '\)'; patterns = (
          { include = '#qq_string_content'; },
       );
    },
    …
 ); // end of patterns
 repository = {
    qq_string_content = {
       begin = '\('; end = '\)'; patterns = (
          { include = '#qq_string_content'; },
       );
    };
 };
```
以上能正确匹配出如qq( this (is (the) entire) string)的字符串

## 命名约定
TextMate是自由格式的，从这个意义上说，您可以为文档的任何部分分配您希望的任何名称，这些部分可以用语法系统标记，
然后在范围选择器中使用该名称。

然而，也有一些约定，使得一个主题可以针对尽可能多的语言，而不必为每种语言指定几十个规则，
并且可以跨语言重用功能（主要是首选项），例如，当插入字符串和注释时，您可能不希望撇号自动配对，
不管您使用的是哪种语言，所以只设置一次是有意义的。


在进行约定之前，请记住以下几点：

1. 一个最小的主题只会将样式分配给下面11个根组中的10个（meta没有视觉样式），所以你应该“分散”你的命名，
也就是说，不要把所有的东西都放在keyword下面（正如你的正式语言定义所坚持的那样），
你应该想“我希望这两个元素的样式不同吗？”？如果是这样的话，它们应该被分成不同的根组。

2. 即使您应该“分散”您的名称，但当您找到要放置元素的组（例如storage）时，您应该重新使用该组下面使用的现有名称
（对于modifier或type的storage），而不是创建一个新的子类型。但是，您应该将尽可能多的信息附加到您选择的子类型中。
例如，如果要匹配static存储修饰符，而不是仅仅使用storage.modifier.static.«language»命名storage.modifer。
storage.modifier的作用域只是将两者都匹配，但名称中包含额外信息意味着有可能专门针对它而忽略其他存储修饰符。

3.在名字后面加上语言名称。这似乎是多余的，因为您通常可以使用域选择器：source.«language».storage.modifier，
但在嵌入语言时，这并不总是可能的。

现在有11个根组正在使用，并对它们的预期用途做了一些解释。这是一个分层列表，
但实际的作用域名称是通过将每个级别的名称与一个点连接起来获得的。例如，double-slash是comment.line.double-slash。

- comment：注释
    - line：行注释，我们进一步专门化，以便可以从范围中提取注释开始字符的类型
        - double-slash：// 注释
        - double-dash：-- 注释
        - number-sign：# 注释
        - percentage：% 注释
        - character：其他类型行注释
    - block：多行注释如/*...*/和<!--...-->
        - documentation：嵌入式文档

- constant：各种形式的常量
    - numeric：数字
    - character：字符
        - escape：转义字符如\e将是constant.character.escape
    - language：由语言提供的常量，如true、false、nil、YES、NO等。
    - other：其他常量，如颜色值

- entity：实体指文档的较大部分，例如章节、类、函数或标记。我们不把整个实体作为entity.*（我们使用meta.*来实现）。
但我们确实使用entity.*作为较大实体中的“占位符”，例如，如果实体是一个章节，
我们将使用entity.name.section对于章节标题
    - name：较大实体的命名
        - function：函数名称
        - type：类声明类型名称
        - tag 标签名称
        - section：名称是节/标题的名称。
    - other：其他实体
        - inherited-class：超类或基类名称
        - attribute-name：属性名称
        
- invalid：无效的一些东西
    - illegal：非法，HTML中的与号或小于号字符（不是实体/标记的一部分）。
    - deprecated：对于不推荐使用的内容，例如使用不推荐使用的API函数或使用严格的HTML进行样式设置。
    
- keyword：关键字
    - control：控制流程如：continue,while,return等
    - operator：操作符文本或字符
    - other：其他关键字

- markup：这适用于标记语言，通常适用于较大的文本子集
    - underline：下划线文本
        - link：这是为了链接，为了方便起见，这是从markup.underline如果没有主题规则markup.underline.link，然后它将继承下划线样式。
    - bold：加粗文本
    - heading：章节开头，可选地提供标题级别作为下一个元素，例如markup.heading.2.html用于html中的<h2>…</h2>。
    - italic：斜体文本
    - list：列表项
        - numbered：数字式列表项
        - unnumbered：非数字式列表项
    - quote：带引号（有时是块引号）的文本。
    - raw：逐字记录的文本，例如代码列表。通常对禁用拼写检查markup.raw
    - other：其他标记结构
    
- meta：元作用域通常用于标记文档的较大部分。例如，声明函数的整行将是meta.function而子集是storage.type, 
entity.name.function, variable.parameter等等，只有后者才会被设计。
有时，作用域的元部分只用于限制样式更一般的元素，但是大多数时间元作用域都用于作用域选择器以激活捆绑项目。
例如，在Objective-C中，类和实现的接口声明有一个元范围，允许相同的选项卡触发器根据上下文不同展开。


- storage：与“储存”有关的东西
    - type：类型相关，class、function、int、var等的类型
    - modifier：存储修改器，如：static,final,abstract等
    
- string：字符串
    - quoted：字符串引用
        - single：带单引号的字符串
        - double：带双引号的字符串
        - triple：三引号字符串
        - other：其他字符串引用
    - unquoted：未带引用
    - interpolated：求值字符串，如：`date`,$(pwd)等
    - regexp：正则表达式
    - other：其他类型字符串
    
- support：框架或库提供的东西应该低于support
    - function：框架或库提供的函数
    - class：框架或库提供的类
    - type：由框架/库提供的类型，这可能只用于从C派生的语言，它具有typedef（和struct）。大多数其他语言都会引入新类型作为类。
    - constant：框架或库提供的常量
    - variable：框架或库提供的变量
    - other： 以上内容应详尽无遗，但对于其他所有内容，请使用support.other

- variable：变量
    - parameter：参数声明
    - language：语言自带的如：this,super,self等
    - other：其他变量，如$some_variables
        





