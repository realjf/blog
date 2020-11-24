---
title: "VS Code扩展开发 之 语言的语法高亮 Language Extension Syntax Highlight"
date: 2020-11-24T12:07:13+08:00
keywords: ["vscode", "extension", "language", "lang"]
categories: ["vscode"]
tags: ["vscode"]
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

## 简介

语法高亮显示确定在VisualStudio代码编辑器中显示的源代码的颜色和样式。
它负责在JavaScript中为if或for等关键字着色，这与字符串、注释和变量名不同

语法高亮有两个组件：

- Tokenization：符号化，将文本拆分为符号列表
- Theming：支持主题，使用主题或用户设置将符号映射到特定的颜色和样式

在深入讨论细节之前，一个好的开始是使用scopeinspector工具并探索源文件中存在哪些标记以及它们与哪些主题规则匹配。
要同时查看语义和语法标记，请在TypeScript文件中使用内置主题（例如，Dark+）

## 符号化

文本的符号化是将文本分成若干段，并用标记类型对每个段进行分类。

VS代码的标记化引擎由[TextMate语法](https://macromates.com/manual/en/language_grammars)驱动。TextMate语法是正则表达式的结构化集合，
以plist（XML）或JSON文件的形式编写。
语法扩展可以通过语法贡献点的贡献。

TextMate符号化引擎在与呈现器相同的进程中运行，标记会随着用户类型的变化而更新。
标记用于语法高亮显示，但也用于将源代码分类为注释、字符串和正则表达式区域。

从版本1.43开始，VS代码还允许扩展通过
[语义标记提供者](https://code.visualstudio.com/api/references/vscode-api#DocumentSemanticTokensProvider)
为程序提供标记化。典型的是，
在项目服务器中实现的符号和语义的源代码一般都可以理解。例如，
可以在整个项目中使用常量高亮显示来呈现常量变量名，而不仅仅是在声明的地方。


基于语义标记的高亮显示被认为是对基于TextMate的语法高亮显示的补充。
语义突出显示在语法突出显示之上。由于语言服务器需要一段时间来加载和分析项目，
语义标记高亮显示可能会在短时间延迟后出现。


本文主要讨论基于TextMate的标记化。语义标记化和主题化在
[语义高亮指南](https://code.visualstudio.com/api/language-extensions/semantic-highlight-guide)中解释


### TextMate 语法

VS代码使用[TextMate语法](https://macromates.com/manual/en/language_grammars)作为语法标记化引擎。
它们是为TextMate编辑器而发明的，
由于开源社区创建和维护了大量的语言包，因此被许多其他编辑器和ide采用。

TextMate语法依赖于[Oniguruma正则表达式](https://macromates.com/manual/en/regular_expressions)，
通常以plist或JSON的形式编写。您可以在[这里](https://www.apeth.com/nonblog/stories/textmatebundle.html)找到对TextMate语法的很好的介绍，
并且可以查看现有的TextMate语法，以了解它们是如何工作的

### TextMate标记和作用域
标记是同一程序元素的一个或多个字符。示例标记包括运算符（如+和*）、变量名（如myVar）或字符串（如“my string”）。

每个token都与定义token上下文的作用域相关联。作用域是一个点分隔的标识符列表，用于指定当前token的上下文。
例如，JavaScript中的+操作具有作用域关键字.运算符.算术.js。

主题将范围映射到颜色和样式，以提供语法高亮显示。TextMate提供了许多主题所针对的[通用范围的列表](https://macromates.com/manual/en/language_grammars)。
为了尽可能广泛地支持您的语法，请尝试在现有范围上构建，而不是定义新的范围。

作用域嵌套，以便每个token也与父作用域的列表相关联。
下面的示例使用[范围检查器](https://code.visualstudio.com/api/language-extensions/syntax-highlight-guide#scope-inspector)
在一个简单的JavaScript函数中显示+运算符的范围层次结构。
最具体的作用域列在顶部，更一般的父作用域列在下面：

![范围检查器](https://code.visualstudio.com/assets/api/language-extensions/syntax-highlighting/scopes.png)

父范围信息也用于创建主题。当主题以某个范围为目标时，所有具有该父作用域的标记都将被着色，
除非该主题还为其各自的作用域提供了更具体的着色

### 添加 基本语法
VS代码支持json TextMate语法。这些都是通过grammars[贡献点](https://code.visualstudio.com/api/references/contribution-points)贡献的。

每个语法贡献都指定：语法应用于的语言的标识符、语法标记的顶级作用域名称以及语法文件的相对路径。
下面的示例显示了虚构的abc语言的语法贡献：

```json
{
  "contributes": {
    "languages": [
      {
        "id": "abc",
        "extensions": [".abc"]
      }
    ],
    "grammars": [
      {
        "language": "abc",
        "scopeName": "source.abc",
        "path": "./syntaxes/abc.tmGrammar.json"
      }
    ]
  }
}
```

语法文件本身由一个顶级规则组成。这通常分为一个模式部分，其中列出程序的顶层元素，以及定义每个元素的repository。
语法中的其他规则可以使用{“include”：“#id”}引用repository 中的元素。

以下示例abc语法将字母a、b和c标记为关键字，并将parens嵌套标记为表达式。
```json
{
  "scopeName": "source.abc",
  "patterns": [{ "include": "#expression" }],
  "repository": {
    "expression": {
      "patterns": [{ "include": "#letter" }, { "include": "#paren-expression" }]
    },
    "letter": {
      "match": "a|b|c",
      "name": "keyword.letter"
    },
    "paren-expression": {
      "begin": "\\(",
      "end": "\\)",
      "beginCaptures": {
        "0": { "name": "punctuation.paren.open" }
      },
      "endCaptures": {
        "0": { "name": "punctuation.paren.close" }
      },
      "name": "expression.group",
      "patterns": [{ "include": "#expression" }]
    }
  }
}
```
语法引擎将尝试连续地将expression规则应用于文档中的所有文本。对于一个简单的程序，例如：

```
a
(
    b
)
x
(
    (
        c
        xyz
    )
)
(
a
```
示例语法生成以下范围（从最具体到最不具体的范围从左到右列出）：
```
a               keyword.letter, source.abc
(               punctuation.paren.open, expression.group, source.abc
    b           keyword.letter, expression.group, source.abc
)               punctuation.paren.close, expression.group, source.abc
x               source.abc
(               punctuation.paren.open, expression.group, source.abc
    (           punctuation.paren.open, expression.group, expression.group, source.abc
        c       keyword.letter, expression.group, expression.group, source.abc
        xyz     expression.group, expression.group, source.abc
    )           punctuation.paren.close, expression.group, expression.group, source.abc
)               punctuation.paren.close, expression.group, source.abc
(               punctuation.paren.open, expression.group, source.abc
a               keyword.letter, source.abc
```

请注意，与其中一个规则（如字符串xyz）不匹配的文本包含在当前范围中。文件末尾的最后一个括号不是expression.group因为结束规则不匹配

### 嵌入式语言

如果语法包含父语言中的嵌入语言，例如HTML中的CSS样式块，则可以使用embeddedLanguages贡献点告诉VS代码将嵌入的语言视为不同于父语言。
这确保了括号匹配、注释和其他基本语言功能在嵌入式语言中按预期工作。

embeddedLanguages贡献点将嵌入语言中的域映射到顶级语言范围。
在下面的示例中meta.embedded.block.javascript域将被视为javascript内容：
```json
{
  "contributes": {
    "grammars": [
      {
        "path": "./syntaxes/abc.tmLanguage.json",
        "scopeName": "source.abc",
        "embeddedLanguages": {
          "meta.embedded.block.javascript": "javascript"
        }
      }
    ]
  }
}
```
现在，如果您尝试在标记的一组标记内注释代码或触发代码段meta.embedded.block.javascript，
它们将获得正确的//javascript样式注释和正确的javascript片段


### 开发一个新的语法扩展
要快速创建新的语法扩展，请使用VS Code的[Yeoman模板](https://code.visualstudio.com/api/get-started/your-first-extension)
来运行yo代码并选择new Language选项：

```shell script
yo code
```
![new grammar](https://code.visualstudio.com/assets/api/language-extensions/syntax-highlighting/yo-new-language.png)

Yeoman将带你通过一些基本问题来构建新的扩展。创建新语法的重要问题是：

- Language Id：你的语言唯一id
- Language Name：你语言的人类可读名字
- Scope names：你的语法的根TextMate语法作用域名称

```shell script

     _-----_     ╭──────────────────────────╮
    |       |    │   Welcome to the Visual  │
    |--(o)--|    │   Studio Code Extension  │
   `---------´   │        generator!        │
    ( _´U`_ )    ╰──────────────────────────╯
    /___A___\   /
     |  ~  |
   __'.___.'__
 ´   `  |° ´ Y `

? What type of extension do you want to create? New Language Support
Enter the URL (http, https) or the file path of the tmLanguage grammar or press ENTER to start with a new grammar.
? URL or file to import, or none for new:
? What's the name of your extension? as86 assembler
? What's the identifier of your extension? as86-assembler
? What's the description of your extension? Syntax highlighting for as86 assembler
Enter the id of the language. The id is an identifier and is single, lower-case name such as 'php', 'javascript'
? Language id: as86
Enter the name of the language. The name will be shown in the VS Code editor mode selector.
? Language name: as86
Enter the file extensions of the language. Use commas to separate multiple entries (e.g. .ruby, .rb)
? File extensions: .s
Enter the root scope name of the grammar (e.g. source.ruby)
? Scope names: source.s
? Initialize a git repository? Yes
   create as86-assembler\syntaxes\as86.tmLanguage.json
   create as86-assembler\.vscode\launch.json
   create as86-assembler\package.json
   create as86-assembler\README.md
   create as86-assembler\CHANGELOG.md
   create as86-assembler\vsc-extension-quickstart.md
   create as86-assembler\language-configuration.json
   create as86-assembler\.vscodeignore
   create as86-assembler\.gitignore
   create as86-assembler\.gitattributes

Your extension as86-assembler has been created!

To start editing with Visual Studio Code, use the following commands:

     cd as86-assembler
     code .

Open vsc-extension-quickstart.md inside the new extension for further instructions
on how to modify, test and publish your extension.

For more information, also visit http://code.visualstudio.com and follow us @code.
```
生成器假定您要为该语言定义新语言和新语法。如果要为现有语言创建语法，只需使用目标语言的信息填充这些语法，
并确保在生成的包.json.

在回答完所有问题后，Yeoman将创建一个新的扩展结构：

![folder-structure](/image/as86-extension-folder-structure.png)

请记住，如果您要将建立一个vs code已经知道的语言的语法，请确保在生成的package.json文件中删除该语言contribution point

#### 转换现有的TEXTMATE语法
yo code还可以帮助将现有的TextMate语法转换为VS代码扩展。再次，从运行yo code并选择Language extension开始。
当要求提供现有语法文件时，请提供指向.tmLanguage或.json TextMate语法文件的完整路径：

#### 用YAML写语法
随着语法变得越来越复杂，很难将其理解为json并将其维护为json。
如果您发现自己正在编写复杂的正则表达式或需要添加注释来解释语法的各个方面，请考虑使用yaml来定义语法。

Yaml语法与基于json的语法具有完全相同的结构，但是允许您使用Yaml更简洁的语法以及多行字符串和注释等特性。

VS Code只能加载json语法，所以基于yaml语法的必须转换为json，js-yaml包和命令如下：
```shell script
# Install js-yaml as a development only dependency in your extension
$ npm install js-yaml --save-dev

# Use the command-line tool to convert the yaml grammar to json
$ npx js-yaml syntaxes/abc.tmLanguage.yaml > syntaxes/abc.tmLanguage.json 
```

### 注入语法
注入语法让你可以扩展已存在的语法，注入语法是一种常规的文本匹配语法，
它被注入到现有语法中的特定范围中。注入文法的应用实例

- 高亮关键字，像TODO等注释
- 向现有语法中添加更多指定域信息
- 为标记围栏代码块添加新语言的高亮显示。

#### 创建基本的注入语法
注入语法通过package.json就像普通语法一样。但是，注入语法不是指定语言，
而是使用injectTo指定要将语法注入到的目标语言范围的列表。

对于本例，我们将创建一个简单的注入语法，在JavaScript注释中将TODO突出显示为关键字。
为了在JavaScript文件中应用注入语法，我们使用source.js在injectTo中的目标语言作用域
```json
{
  "contributes": {
    "grammars": [
      {
        "path": "./syntaxes/injection.json",
        "scopeName": "todo-comment.injection",
        "injectTo": ["source.js"]
      }
    ]
  }
}
```
语法本身是标准的TextMate语法，但顶级injectionSelector条目除外。
injectionSelector是一个域选择器，它指定应将注入的语法应用于哪些域。
对于我们的示例，我们希望在所有//注释中突出显示TODO这个词。使用域检查器，
我们发现JavaScript的双斜杠注释具有域comment.line.double-slash，所以我们的注射选择器是
L:comment.line.double-slash：

```json
{
  "scopeName": "todo-comment.injection",
  "injectionSelector": "L:comment.line.double-slash",
  "patterns": [
    {
      "include": "#todo-keyword"
    }
  ],
  "repository": {
    "todo-keyword": {
      "match": "TODO",
      "name": "keyword.todo"
    }
  }
}
```
注入选择器中的L:表示注入被添加到现有语法规则的左侧。这基本上意味着我们注入的语法规则将在任何现有语法规则之前应用。

#### 嵌入式语言
注入语法也可以为它们的父语法贡献嵌入式语言。与普通语法一样，
注入语法可以使用embeddedLanguages将域从嵌入语言映射到顶级语言域。

例如，在JavaScript字符串中突出显示SQL查询的扩展可以使用embeddedLanguages来确保标记的字符串内的所有标记
meta.embedded.inline.sql对于基本语言功能（如括号匹配和代码段选择）被视为sql。

```json
{
  "contributes": {
    "grammars": [
      {
        "path": "./syntaxes/injection.json",
        "scopeName": "sql-string.injection",
        "injectTo": ["source.js"],
        "embeddedLanguages": {
          "meta.embedded.inline.sql": "sql"
        }
      }
    ]
  }
}

```
#### token类型和嵌入式语言
对于嵌入语言的注入语言来说，还有一个额外的复杂性：默认情况下，VS代码将字符串中的所有标记视为字符串内容，
将带有注释的所有标记视为令牌内容。由于诸如括号匹配和自动结束对之类的功能在字符串和注释中被禁用，
如果嵌入的语言出现在字符串或注释中，这些功能也将在嵌入语言中被禁用。

若要重写此行为，可以使用 meta.embedded.* 重置VS代码将标记标记为字符串或注释内容的范围。
总是将嵌入式语言包装在 meta.embedded.* 确保VS代码正确处理嵌入语言的范围。

如果不能添加 meta.embedded.* 域到您的语法，您也可以使用语法贡献点中的标记类型将特定范围映射到内容模式。
下面的tokenTypes部分确保 my.sql.template.string 作用域被视为源代码：
```json
{
  "contributes": {
    "grammars": [
      {
        "path": "./syntaxes/injection.json",
        "scopeName": "sql-string.injection",
        "injectTo": ["source.js"],
        "embeddedLanguages": {
          "my.sql.template.string": "sql"
        },
        "tokenTypes": {
          "my.sql.template.string": "other"
        }
      }
    ]
  }
}
```

## 主题化
主题化是指为标记指定颜色和样式。主题化规则在颜色主题中指定，但用户可以在“用户设置”中自定义主题化规则。

TextMate主题规则在tokenColors中定义，其语法与常规TextMate主题相同。
每个规则都定义一个TextMate范围选择器和结果颜色和样式。

在计算token的颜色和样式时，当前token的域作用域将与规则的选择器相匹配，
以查找每个样式属性（前景、粗体、斜体、下划线）的最具体规则

[颜色主题指南](https://code.visualstudio.com/api/extension-guides/color-theme#syntax-colors)介绍如何创建颜色主题。
语义标记的主题化在[语义突出显示指南](https://code.visualstudio.com/api/language-extensions/semantic-highlight-guide#theming)中进行了说明

## 作用域检查器
VS代码的内置范围检查器工具有助于调试语法和语义标记。
它显示标记的作用域和文件中当前位置处的语义标记，以及有关应用于该标记的主题规则的元数据。

使用Developer:Inspect Editor Tokens and Scopes命令从命令调色板触发范围检查器，
或为其创建[keybinding](https://code.visualstudio.com/docs/getstarted/keybindings)：
```json
{
  "key": "cmd+alt+shift+i",
  "command": "editor.action.inspectTMScopes"
}
```
范围检查器显示以下信息：

- 当前token。
- 有关token的元数据及其计算外观的信息。如果您使用的是嵌入式语言，这里的重要条目是语言和token类型。
- 当语义标记提供程序可用于当前语言且当前主题支持语义高亮显示时，将显示语义标记部分。它显示当前语义标记类型和修饰符，以及匹配语义标记类型和修饰符的主题规则。
- TextMate部分显示当前TextMate令牌的作用域列表，最具体的作用域位于顶部。它还显示了与范围匹配的最具体的主题规则。这只显示负责令牌当前样式的主题规则，不显示重写的规则。如果存在语义标记，则只有当主题规则与匹配语义标记的规则不同时才会显示主题规则。



