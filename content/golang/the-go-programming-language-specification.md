---
title: "The Go Programming Language Specification Go 编程语言规范"
date: 2023-02-21T17:04:05+08:00
keywords: ["golang"]
categories: ["golang"]
tags: ["golang"]
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

### 符号

语法是使用 扩展巴科斯范式 (EBNF) 的变体指定的

```go
Syntax      = { Production } .
Production  = production_name "=" [ Expression ] "." .
Expression  = Term { "|" Term } .
Term        = Factor { Factor } .
Factor      = production_name | token [ "…" token ] | Group | Option | Repetition .
Group       = "(" Expression ")" .
Option      = "[" Expression "]" .
Repetition  = "{" Expression "}" .
```

产生式是由术语和以下运算符构造的表达式，优先级递增：

```go
| 交替
() 分组
[] 选项（0 或 1 次）
{} 重复（0 到 n 次）
```




##### **See Also(参见)**

- [go programming language specification](https://go.dev/ref/spec)
