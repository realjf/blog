---
title: "如何使用weak_ptr? How to Use Weak Pointer"
date: 2021-03-09T17:41:32+08:00
keywords: ["cpp", "weak_ptr"]
categories: ["cpp"]
tags: ["cpp", "weak_ptr"]
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

## 如何使用weak_ptr？
使用shared_ptr能自动释放“不再被需要的对象”的资源，避免资源泄漏。但是有以下两种情况可能share_ptr无法正常运作

- 环式指向cyclic reference，如果两对象使用shared_ptr互相指向对方，而一旦不存在其他reference指向它们时，你想释放它们和相应资源时，shared_ptr不会释放数据，因为每个对象的use_count()仍是1，此时你或许会想使用普通的指针，但这样做却要自行管理是释放相应资源了。
- 还有一种是你明确想共享但不愿拥有某对象的情况下，你要的语义是：reference的寿命比其所指向对象的寿命更长，因此，shared_ptr绝不释放对象，而普通指针可能不会注意到他们指向的对象已经不再有效，导致“访问已被释放的对象”的风险。

### 解决方案
标准库提供了类weak_ptr，允许你“共享但不拥有”某对象（即可以访问对象数据，但是不能操作对象）。这个weak_ptr建立起一个shared_ptr，一旦最末尾一个拥有该对象的shared_pointer失去了拥有权，任何weak pointer都会自动成空。

因此，在默认构造函数和copy构造函数之外，weak_ptr只提供“接收一个shared_ptr”的构造函数。

你不能使用操作符*和->访问weak_ptr指向的对象，而是必须另外建立一个shared pointer。理由如下：

- 在weak pointer之外建立一个shared pointer可因此检查是否扔存在一个相应对象，如果不，操作会抛出异常或建立一个empty shared pointer（实际究竟哪种行为乃取决于你所执行的是哪一种操作）。
- 当指向的对象正被处理时，shared pointer无法被释放

基于以上理由，weak_ptr只提供小量操作，只够用来创建、复制、赋值weak pointer。以及转换为一个shared pointer，或检查自己是否指向某对象。

### weak_ptr使用示例
首先是使用shared_ptr构建环形指向引用。

```cpp
#include <iostream>
#include <string>
#include <vector>
#include <memory>
using namespace std;

class Person {
    public:
    string name;
    shared_ptr<Person> mother;
    shared_ptr<Person> father;
    vector<shared_ptr<Person>> kids;

    Person(const string& n, shared_ptr<Person> m= nullptr, shared_ptr<Person> f =nullptr)
    : name(n), mother(m), father(f)
    {

    }
    ~Person(){
        cout << "delete " << name << endl;
    }
};

shared_ptr<Person> initFamily(const string& name)
{
    shared_ptr<Person> mom(new Person(name+"'s mom"));
    shared_ptr<Person> dad(new Person(name+"'s dad"));
    shared_ptr<Person> kid(new Person(name, mom, dad));
    mom->kids.push_back(kid);
    dad->kids.push_back(kid);
    return kid;
}

int main()
{
    shared_ptr<Person> p = initFamily("nico");

    cout << "nico's family exists"<< endl;
    cout << "- nico is shared " << p.use_count() << " times" << endl;
    cout << "- name of 1st kid of nico's mom: " << p->mother->kids[0]->name << endl;

    p = initFamily("jim");
    cout << "jim's family exists" << endl;
}

```

如上，p是指向上述家庭的最末一个handle。而在内部，每个person对象都有着reference从kid指向其父母以及反向指向。因此，在p被赋值之前，nico被共享三次，现在，如果我们释放手上最末一个指向该家庭的handle——也许是对p指派一个新person或一个nullptr，也许是main()结束时离开了p作用域——没有任何person会被释放，因为它们都至少被一个shared pointer指向，于是每个person的析构函数从未被调用：

```sh
nico's family exists
- nico is shared 3 times
- name of 1st kid of nico's mom: nico
jim's family exists
```

![一个只使用shared_ptr的家庭](/image/only_shared_pointer.png)


#### 现在使用weak_ptr代替其中的部分shared_ptr，使其环形指向去除
```cpp
#include <iostream>
#include <string>
#include <vector>
#include <memory>
using namespace std;

class Person {
    public:
    string name;
    shared_ptr<Person> mother;
    shared_ptr<Person> father;
    vector<weak_ptr<Person>> kids; // 使用 weak_ptr

    Person(const string& n, shared_ptr<Person> m= nullptr, shared_ptr<Person> f =nullptr)
    : name(n), mother(m), father(f)
    {

    }
    ~Person(){
        cout << "delete " << name << endl;
    }
};

shared_ptr<Person> initFamily(const string& name)
{
    shared_ptr<Person> mom(new Person(name+"'s mom"));
    shared_ptr<Person> dad(new Person(name+"'s dad"));
    shared_ptr<Person> kid(new Person(name, mom, dad));
    weak_ptr<Person> wkid(kid);
    mom->kids.push_back(wkid);
    dad->kids.push_back(wkid);
    return kid;
}

int main()
{
    shared_ptr<Person> p = initFamily("nico");

    cout << "nico's family exists"<< endl;
    cout << "- nico is shared " << p.use_count() << " times" << endl;
    // weak_ptr改变访问方式，使用lock()函数
    cout << "- name of 1st kid of nico's mom: " << p->mother->kids[0].lock()->name << endl;

    p = initFamily("jim");
    cout << "jim's family exists" << endl;
}
```
这样处理后，使得在一个方向上（从kid到parent）用的是shared pointer，而从parent到kids则使用weak pointer

![一个同时使用shared_ptr和weak_ptr的家庭](/image/shared_and_weak_pointer.png)

经过改造后，程序输出如下：
```sh
nico's family exists
- nico is shared 1 times
- name of 1st kid of nico's mom: nico
delete nico
delete nico's dad
delete nico's mom
jim's family exists
delete jim
delete jim's dad
delete jim's mom
```

> 注意：使用weak pointer时，调用方式改成p->mother->kids[0].lock()->name

这会导致新产生一个来自于kids容器内含之weak_ptr的shared_ptr，如果无法进行这样的改动——例如由于对象的最末拥有者也在此时释放了对象——lock()会产生一个empty shared_ptr。这种情况下调用*或->操作符会引发不明确行为。

如果不确定隐身于weak pointer背后的对象是否仍然存活，你有以下几个选择：

- 1.调用expired()，它会在weak_ptr不再共享对象时返回true。这等于检查use_count()是否为0，但速度较快。
- 2. 可以使用相应的shared_ptr构造函数明确将weak_ptr转换为一个shared_ptr。如果被指对象已经不存在，该构造函数会抛出一个bad_weak_ptr异常，那是一个派生自std::exception的异常，其what()会产生“bad_weak_tr"
- 3. 调用use_count()，询问相应对象的拥有者数量，如果返回0表示不存在任何有效对象，然而请注意，通常只应为了调式而调用use_count()：c++标准库明确告诉我们：“use_count()并不总是很有效率”

举例：

```cpp
try{
  shared_ptr<string> sp(new string("hi"));
  weak_ptr<string> wp = sp;  // create weak pointer out of it
  sp.reset(); // release object of shared pointer
  count << wp.use_count() << endl; // prints: 0
  cout << boolalpha << wp.expired() << endl; // prints: true
  shared_ptr<string> p(wp); // throws std::bad_weak_ptr
}catch( const std::exception& e){
  cerr << "exception: " << e.what() << endl; // prints: bad_weak_ptr
}
```



