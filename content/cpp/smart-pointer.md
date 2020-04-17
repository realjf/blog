---
title: "C++智能指针详解（Smart Pointer）"
date: 2020-04-17T11:21:57+08:00
keywords: ["智能指针"]
categories: ["cpp"]
tags: ["智能指针"]
series: [""]
draft: true
toc: false
related:
  threshold: 80
  includeNewer: false
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

### 智能指针
智能指针在C++11版本之后提供，包含在头文件<memory>中，包括三种：
- shared_ptr
- unique_ptr
- weak_ptr

### 智能指针的作用
由于C++没有垃圾回收机制，一切内存堆操作都是程序员自己管理，但对于程序员来说管理堆不胜麻烦，稍有不慎忘记释放就会造成内存泄露最终导致内存溢出等问题。
而智能指针则能有效避免此类问题发生。

智能指针通过对普通指针进行类封装，使其表现的跟普通指针类似的行为。

#### shared_ptr类指针
shared_ptr 使用引用计数，每一个shared_ptr的拷贝都指向相同的内存地址，
 



