---
title: "const修饰指针 Const Modify Pointer"
date: 2021-03-02T22:14:11+08:00
keywords: ["cpp"]
categories: ["cpp"]
tags: ["cpp"]
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

### const修饰指针
#### const int *p
- 可以修改p
- 不可以修改*p

#### int const *p
- 可以修改p
- 不可以修改*p
（同上）

#### int * const p
- 可以修改 *p
- 不可以修改 p


#### const int * const p 
- 不可以修改p
- 不可以修改*p

### 总结
const向右修饰，被修饰的部分即为只读
