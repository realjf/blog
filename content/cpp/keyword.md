---
title: "C++常用关键字用法解析 const static volatile extern mutable"
date: 2020-04-22T18:09:41+08:00
keywords: ["", "cpp"]
categories: ["cpp"]
tags: ["", "cpp"]
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

### static
#### 修饰局部变量
- 静态局部变量只作用于其定义的函数期间，函数结束，其所占用的内存空间也被回收。
- 在静态存储区分配空间，只初始化一次

#### 修饰全局变量
- 也称静态全局变量，其作用域在定义它的文件里，不能作用于其他文件。
- 静态全局变量在静态存储区分配空间，在程序开始运行时完成初始化，也是唯一的一次初始化


#### 修饰函数
- 静态函数只在声明它的文件中可见，不能被其他文件使用。

#### 修饰类成员
- 对于静态类成员，它属于类，而不属于某个对象实例，多个对象之间共享静态类成员
- 静态类成员存储于静态存储区，生命周期为整个程序执行期
- 静态类成员需要初始化，且在类外初始化，默认初始化为0

初始化方法：<数据类型> <类名>::<静态类成员>=<值>

#### 修饰类成员函数
- 同样静态类成员函数属于整个类，而非某个实例对象，也没有this指针，需要通过类名进行访问。
- 不能将静态类成员函数定义为虚函数
> 虚函数依赖vptr和vtable，vptr通过类的构造函数生成，且只能用this指针访问，这也就是为什么静态成员函数不能是虚函数的原因
- 由于静态成员函数没有this指针，所以就差不多等同于nonmember函数，结果就产生了一个意想不到的好处：成为一个callback函数，使得我们得以将C++和C-based X Window系统结合，同时也成功的应用于线程函数身上
- 为了防止父类的影响，可以在子类定义一个与父类相同的静态变量，以屏蔽父类的影响。



### const
规则：const离谁近，谁就不能被修改，只读的意思，且需要初始化。
####  修饰基本数据类型
- 修饰一般常量时，可以在类型说明符前也可以在其后，只要在使用时不改变常量即可。
- const修饰指针变量*及引用变量&
> 如果const位于星号*的左侧，则const就是用来修饰指针所指向的变量，即指针指向为常量
> 如果const位于星号的右侧，const就是修饰指针本身，即指针本身是常量

#### 作为函数参数的修饰符
用相应的变量初始化const常量，则在函数体中，按照const所修饰的部分进行常量化，保护了原对象的属性不被修改
```c
void say(const char* str){...}
```

#### 作为函数返回值的修饰符
声明了返回值后，对返回值起到保护作用，即使得其返回值不为“左值”，只能作为右值使用。
```c
const int add(int a, int b){...}
```

#### const修饰类成员
修饰的类成员的初始化只能在类的构造函数的初始化表中进行

#### const修饰类成员函数
作用是修饰的成员函数不能修改类的任何成员变量
```c
int funcA() const {}
```

#### const修饰类对象，定义常量对象
常量对象只能调用常量函数，别的成员函数都不能调用。


### volatile

>cpu访问寄存器要比访问内存快，所有会优先访问寄存器的数据，但是可能出现寄存器中还是旧数据，内存中的数据已经改变，为了避免这种情况发生，
>将变量声明为volatile，告诉cpu每次都从内存中去读取数据。

#### 多线程下的volatile
应用到多线程中就是，一个线程改变了变量值，怎么让改变后的值对其他线程可见，一般采用如下做法：

- 中断服务程序中, 修改的供其他程序检测的变量要加volatile
- 多线程共享的标志变量应该加volatile
- 存储器映射的硬件寄存器也要加volatile

#### volatile指针
- 修饰由指针指向的对象，数据是const或volatile
```c
const char* p1;
volatile char* p2;

```
- 指针自身的值，一个代表地址的整数变量，是const或volatile
```c
char* const p3;
char* volatile p4;
```
- 可以把一个非volatile int赋给volatile int，但是不能把非volatile对象赋给一个volatile对象
- C++中一个有volatile标识符的类只能访问它接口的子集，一个由类的实现者控制的子集。用户只能用const_cast来获得对类型接口的完全访问。此外，volatile像const一样会从类传递到它的成员



### extern
extern用在变量或函数声明前，用来说明此变量或函数在别处定义，引入此处。

#### extern C 的作用
连接指示符extern C，程序员用链接指示符告诉编译器该函数是用其他的程序设计语言编写的，链接指示符有两种形式既可以是单一语句形式也可以是复合语句形式。

```c
// 单一语句形式的链接指示符
extern "C" void say();

// 复合语句形式的链接指示符
extern "C" {
    void say( const char* ... );
    void draw( const char* ... );
}
// 复合语句形式的链接指示符
extern "C" {
    #include <string>
}
```

### mutable
只能用于类的非静态和非常量数据成员

如果一个类成员函数被声明为const类型，表示该函数不会改变对象的状态，也就是该函数不会修改类的非静态成员，
但是有时候需要在该类函数中对类的数据成员进行赋值，这时候就需要用mutable关键字了。



