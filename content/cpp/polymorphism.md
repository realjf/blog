---
title: "C++多态与虚函数 （Polymorphism）"
date: 2020-04-17T14:04:30+08:00
keywords: ["多态", "虚函数", "cpp"]
categories: ["cpp"]
tags: ["多态", "虚函数", "cpp"]
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

### 什么是多态？
C++的多态即针对同一事物对不同场景表现多种形态，称为c++的多态性

**多态分为静态多态和动态多态**
- 静态多态又分为函数重载和泛型编程
- 动态多态则通过虚函数实现

### 多态的作用
- 提供了接口与具体实现之间的另一层隔离，
- 改善了代码的组织结构和可读性以及可扩展性

#### 静态多态
直接上代码
```cpp
int Add(int a, int b)
{
    return a + b;
}

double Add(float a, float b)
{
    return a + b;
}

// 调用的时候
int main()
{
    Add(1, 2); // 调用的是第一个Add
    Add(1.5, 2.5); // 调用的是第二个Add
    
    return 0;
}
```
可以看到，静态多态是在编译期间可以确定的，根据具体的了类型调用不同的函数

#### 动态多态
首先要理解，这里的动态是指在程序运行期间，所以动态多态只能在程序运行的时候确定。

而要实现动态多态，这里需要用到关键字virtual，声明一个函数为虚函数

具体代码：
```cpp
class Animal
{
    public:
      virtual void Say() = 0;
}

class Cow : public Animal
{
public:
    void Say()
    {
        cout << "哞哞" << endl;
    }
}

class Sheep : public Animal
{
public:
    void Say()
    {
        cout << "咩咩" << endl;
    }
}

// 开始使用
int main()
{
    Animal* cow = (Animal*)new Cow();
    Animal* sheep = (Animal*)new Sheep();
    cow->Say();
    sheep->Say();
}

```
有上述代码可以看出，多态是基类中包含虚函数，而子类对其进行重写的，并且通过基类对象的指针或引用调用虚函数形成多态。

#### 与函数重写的区别
- 函数重写是，子类重写父类函数，则调用子类函数时会屏蔽父类的函数，同样调用父类函数时也会屏蔽子类函数。
- 多态的基类函数必须是虚函数，而重写的不是

### 多态的实现原理
这种多态是由编译器在幕后完成的。为了实现这个多态，编译器对每个包含虚函数的类创建一个表（称为VTABLE）。
在VTABLE中，编译器放置特定类的虚函数的地址。在每个带有虚函数的类中，编译器都会放置一个指针，称为vpointer，
（缩写VPTR）,指向这个对象的VTABLE，当通过基类指针调用虚函数时，编译器静态地插入能取得这个VPTR并在VTABLE表中查找函数地址的代码，
这样就能实现多态了。








