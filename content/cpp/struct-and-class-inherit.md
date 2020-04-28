---
title: "C++ 的Struct和Class 的区别"
date: 2020-02-22T22:14:22+08:00
keywords: ["cpp struct class", "cpp"]
categories: ["cpp"]
tags: ["cpp struct class", "cpp"]
series: [""]
draft: false
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

### 关于c++的class和struct的不同可以简单归纳为以下几点：

#### 内部成员变量及成员函数的默认防控属性不同
struct默认防控属性是public，而class默认的防控属性是Private

#### 继承关系中的默认防控属性的区别
在继承关系中，struct默认是public，而class是private

在继承中的基类和子类之间的继承方式

| 继承方式 | 基类的public成员 | 基类的protected成员 | 基类中的private成员 |
| :---: | :---: | :---: | :---: |
| public继承 | 仍为public成员 | 仍为protected成员 | 不可见 |
| protected继承 | 变为protected成员 | 变为protected成员 | 不可见 |
| private继承 | 变为private成员 | 变为private成员 | 不可见 |


#### 模板中使用
class关键字可以用于定义模板参数，但是struct不行
```c++
template<template T, class Y>

int Func(const T& t, const Y& y)
{
    ...
}
```
#### 使用花括号{}赋值问题
- struct如果没有定义构造函数，可以使用花括号对struct成员进行赋值。
- struct中如果定义了一个构造函数，则不能使用花括号进行赋值




