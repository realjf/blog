---
title: "Makefile 基本语法和规则"
date: 2019-09-30T21:57:15+08:00
keywords: ["devtools", "make", "makefile"]
categories: ["devtools"]
tags: ["devtools", "make", "makefile"]
draft: false
---

## 基本语法
```makefile
target1 target2 target3: prerequisite1 prerequisite2
    command1
    command2
    command3
```
冒号的左边可以出现一个或多个工作目标，而冒号的右边可以出现零个或多个必要条件。
如果冒号的右边没有指定必要条件，那么只有在工作目标所代表的文件不存在时才会进行更新的动作。

每个命令必须以跳格符开头，这个语法用来要求make将紧跟在跳格符之后的内容传给subshell来执行。

make会将#号视为注释字符，从井号开始到该行结束之间的所有文字都会被make忽略。你可以使用反斜线，来延续过长的文本行。


## 规则

    
