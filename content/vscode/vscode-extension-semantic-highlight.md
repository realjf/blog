---
title: "VS Code扩展开发 之 语言的语义高亮 Vscode Extension Semantic Highlight"
date: 2020-11-24T13:30:07+08:00
keywords: ["vscode","extension","semantic"]
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

语义高亮显示是语法高亮显示的补充，如[语法高亮显示指南](/vscode/language-extension-syntax-highlight/)所述。
VisualStudio代码使用TextMate语法作为主要的标记化引擎。TextMate语法作为输入工作在一个文件上，
并根据正则表达式中表达的词汇规则将其分解。

语义标记化允许语言服务器基于语言服务器关于如何在项目上下文中解析符号的知识提供额外的令牌信息。
主题可以选择使用语义标记来改进和优化语法突出显示。编辑器将从语法高亮显示的语义标记应用高亮显示。

下面是一个语义突出显示可以添加的示例：

不带语义高亮显示：
![](https://code.visualstudio.com/assets/api/language-extensions/semantic-highlighting/no-semantic-highlighting.png)

待语义高亮显示：
![](https://code.visualstudio.com/assets/api/language-extensions/semantic-highlighting/with-semantic-highlighting.png)

上述两图颜色不同的说明：

- 第10行：languageMode 是作为参数进行染色
- 第11行：Range和Position是作为类标记，document是作为参数
- 第13行：getFoldingRanges作为函数

## 语义token提供者















