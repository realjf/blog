---
title: "C++如何在对象创建过程中使用this指针指向自己？ Enable Shared From This"
date: 2021-03-10T16:05:21+08:00
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

weak_ptr处理的是循环依赖造成的空荡指针问题，另一个问题是：必须保证某对象只被一组shared pointer拥有。

下面代码是错的：
```cpp
int* p = new int;
shared_ptr<int> sp1(p);
shared_ptr<int> sp2(p);
```
两组拥有权意味着相应资源的释放会被执行两次。

除了上述情况外，也可能间接出现该问题：
```cpp
shared_ptr<Person> mom(new Person(name+"'s mom"));
shared_ptr<Person> dad(new Person(name+"'s dad"));
shared_ptr<Person> kid(new Person(name));
kid->setParentsAndTheirKids(mom, dad);
```
修改Person类，如下：
```cpp
class Person{
  public:
  ...
  void setParentsAndTheirKids(shared_ptr<Person> m = nullptr, shared_ptr<Person> f = nullptr){
    mother = m;
    father = f;
    if(m != nullptr){
      m->kids.push_back(shared_ptr<Person>(this)); // ERROR
    }
    if(f != nullptr){
      f->kids.push_back(shared_ptr<Person>(this)); // ERROR
    }
  }
  ...
};
```
问题出在 “this的那个shared pointer”的建立。之所以这么做，是因为我们想设置mother和father这两个成员的kids。但为了保持创建的kid和mother以及father设置的kid为同一个指针对象，所以需要一个shared pointer指向这个kid，这样就能解决问题，但是我们目前没有，而通过this指针创建将会开启一个新的拥有者，即开启一个新的shared pointer。

为了解决该问题，一种是将指向kid的shared pointer传递为第三个实参。另一种是c++标准库提供的：class std::enable_shared_from_this<>。

你可以从class std::enable_shared_from_this<>派生你自己的class，表现出“被sahred pointer管理”的对象。做法是将class名称当作template实参传入。然后你就可以使用一个派生的成员函数shared_from_this()建立起一个源自this的正确shared_ptr。

```cpp
class Person : public std::enable_shared_from_this<Person>{
  public:
  ...
  void setParentsAndTheirKids(shared_ptr<Person> m = nullptr, shared_ptr<Person> f = nullptr){
    mother = m;
    father = f;
    if(m != nullptr){
      m->kids.push_back(shared_from_this()); // ERROR
    }
    if(f != nullptr){
      f->kids.push_back(shared_from_this()); // ERROR
    }
  }
  ...
};
```

> 注意，不能在构造函数内调用shared_from_this()。

其问题在于shared_ptr本身被存放于Person的base class，也就是enable_shared_from_this<>内部的一个private成员中，在Person构造结束之前。

所以，在初始化shared_ptr的那个对象的构造期间，绝对无法建立shared pointer的循环引用。








