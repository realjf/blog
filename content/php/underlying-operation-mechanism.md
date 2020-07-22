---
title: "php底层运行机制 Underlying Operation Mechanism"
date: 2020-05-18T14:08:10+08:00
keywords: ["php"]
categories: ["php"]
tags: ["php"]
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

php是多进程模型，不同请求间互不干涉，保证了一个请求挂掉不会对其他请求造成影响。目前php也支持多线程模型。

php同时也是弱类型语言，zend引擎+组件（ext）的模式，降低内部耦合，中间层sapi,隔绝web server和php

### php的核心架构
php核心架构如下图，从下到上可以简单分为四层体系：

![/image/php_core_arch.png](/image/php_core_arch.png)

- zend引擎：是php的内核，它将php代码翻译为可执行opcode的处理并实现相应的处理方法，实现了基本的数据结构、内存分配管理、提供了相应的api方法供外部调用，是一切的核心
- Extensions：围绕着zend引擎，extensions通过组件式的方式提供各种基础服务，各种内置函数、标准库等都是通过extensions实现的。
- sapi：全称是Server Application Programming Interface服务端应用编程接口，sapi通过一系列钩子函数，使得php可以和外围交互数据，通过sapi成功的将php本身和上层应用解耦隔离，php可以不再考虑如何针对不同应用进行兼容，而应用本身也可以针对自己特点实现不同处理方式。
    - 常见的一些sapi有：apache2handler: 这是以apache作为webserver，采用mod_php模式运行方式也是应用最广泛的一种
    - cgi：这是webserver和php直接交互的另一种方式，fastcgi+php得到广泛应用，也是异步webserver所唯一支持的方式
    - cli：命令行调用的应用模式
- 上层应用：这是我们平时编写的php程序，通过不同的sapi方式得到各种各样的应用模式


### php执行流程

![/image/php_operating_flow.png](/image/php_operating_flow.png)

php实现了典型动态语言执行过程：将一段代码经过词法解析、语法解析等阶段后，源程序会被翻译成一个个指令（opcodes），
然后zend虚拟机顺次执行这些指令完成操作。php本身是用c实现的，因此最终调用的也是c的函数。

php的执行核心是翻译出来的一条条指令，即opcode。

opcode是php程序执行的最基本单位。一个opcode由两个参数（op1,op2）、返回值和处理函数组成。php程序最终被翻译成一组opcode处理函数的顺序执行。

### zend引擎
zend引擎作为php的内核，有很多经典的设计机制，主要有以下几个：

#### 实现hashTable数据结构：
hashTable是zend的核心数据结构。几乎用来实现所有常见功能。

zend hash table实现了典型的hash表散列结构,同时通过附加一个双向链表，提供了正向、反向遍历数组的功能。其结构如下：

![/image/php_zend_hash_table.png](/image/php_zend_hash_table.png)

在hash table中既有key->value形式的散列结构，也有双向链表模式，使得它能够非常方便的支持快速查找和线性遍历

- 散列结构：Zend的散列结构是典型的hash表模型，通过链表的方式来解决冲突。需要注意的是zend的hash table是一个自增长的数据结构，
当hash表数目满了之后，其本身会动态以2倍的方式扩容并重新元素位置。初始大小均为8。
另外，在进行 key->value快速查找时候，zend本身还做了一些优化，通过空间换时间的方式加快速度。
比如在每个元素中都会用一个变量 nKeyLength标识key的长度以作快速判定。

- 双向链表：Zend hash table通过一个链表结构，实现了元素的线性遍历。
理论上，做遍历使用单向链表就够了，之所以使用双向链表，主要目的是为了快速删除，避免遍历。 
Zend hash table是一种复合型的结构，作为数组使用时，即支持常见的关联数组也能够作为顺序索引数字来使用，甚至允许2者的混合。


- PHP关联数组：关联数组是典型的hash_table应用。

- PHP索引数组：索引数组就是我们常见的数组，通过下标访问。例如 arr[0]，Zend HashTable内部进行了归一化处理，对于index类型key同样分配了hash值和nKeyLength(为0)。内部成员变量 nNextFreeElement就是当前分配到的最大id，每次push后自动加一。正是这种归一化处理，PHP才能够实现关联和非关联的混合。由于 push操作的特殊性，索引key在PHP数组中先后顺序并不是通过下标大小来决定，而是由push的先后决定。


#### php变量实现原理

PHP在变量申明的时候不需要指定类型。PHP在程序运行期间可能进行变量类型的隐示 转换。 
和其他强类型语言一样，程序中也可以进行显示的类型转换。PHP变量可以分为简单类型(int、string、bool)、集合类型(array 、resource 、object)和常量(const)。以上所有的变量在底层都是同一种结构 zval


Zval是zend中另一个非常重要的数据结构，用来标识并实现PHP变量，其数据结构如下

![/image/php_zval_structure.png](/image/php_zval_structure.png)

zval结构主要分三部分：

- type ： 指定了变量所述的类型（整数、字符串、数组等）
- refcount&is_ref：用来实现引用计数
- value：核心部分，存储了变量的实际数据
- Zvalue：是用来保存一个变量的实际数据的，因为要存储多种类型，所以zvalue是一个union，也由此实现了弱类型。

##### 整数、浮点数变量

整数、浮点数是PHP中的基础类型之一，也是一个简单型变量。对于整数和浮点数，在zvalue中直接存储对应的值。其类型分别是long和double。 
从zvalue结构中可以看出，对于整数类型，和c等强类型语言不同，PHP是不区分int、unsigned int、long、long long等类型的，对它来说，整数只有一种类型也就是long。由此，可以看出，在PHP里面，整数的取值范围是由编译器位数来决定而不是固定不变的。 
对于浮点数，类似整数，它也不区分float和double而是统一只有double一种类型。

> 在PHP中，如果整数范围越界了怎么办？这种情况下会自动转换为double类型，这个一定要小心，很多trick都是由此产生

##### 字符变量
字符变量也是PHP中的基础类型和简单型变量。通过zvalue结构可以看出，在PHP中，字符串是由指向实际数据的指针和长度结构体组成，
这点和c++中的string比较类似。由于通过一个实际变量表示长度，和c不同，它的字符串可以是2进制数据（包含\0），
同时在PHP中， 求字符串长度strlen是O(1)操作。

在新增、修改、追加字符串操作时，PHP都会重新分配内存生成新的字符串。最后，出于安全考虑，PHP在生成一个字符串时末尾仍然会添加\0

常见的字符串拼接方式及速度比较：

假设有如下4个变量：strA=‘123’; strB = ‘456’; intA=123; intB=456; 
现在对如下的几种字符串拼接方式做一个比较和说明： 
- res = strA.strB和res = “strAstrB” 这种情况下，zend会重新malloc一块内存并进行相应处理，其速度一般。 
- strA = strA.strB 这种是速度最快的，zend会在当前strA基础上直接relloc，避免重复拷贝 
- res = intA.intB 这种速度较慢，因为需要做隐式的格式转换，实际编写程序中也应该注意尽量避免 
- strA = sprintf (“%s%s”,strA，strB); 这会是最慢的一种方式，因为sprintf在PHP中并不是一个语言结构，本身对于格式识别和处理就需要耗费比较多时间，另外本身机制也是malloc。不过sprintf的方式最具可读性，实际中可以根据具体情况灵活选择。

##### 数组变量
PHP的数组通过Zend HashTable来天然实现。

foreach操作如何实现？对一个数组的foreach就是通过遍历hashtable中的双向链表完成。
对于索引数组，通过foreach遍 历效率比for高很多，省去了key->value的查找。
count操作直接调用 HashTable->NumOfElements，O(1)操作。对于’123’这样的字符串，zend会转换为其整数形式。
arr[‘123’]和arr[123]是等价的


##### 资源变量
资源类型变量是PHP中最复杂的一种变量，也是一种复合型结构。

在zval中，对于resource，lval作为指针来使用，直接指向资源所在的地址。Resource可以是任意的复合结构，我们熟悉的mysqli、fsock、memcached等都是资源。


**如何使用资源：**

- 1 注册：对于一个自定义的数据类型，要想将它作为资源。首先需要进行注册，zend会为它分配全局唯一标示。 
- 2 获取一个资源变量：对于资源，zend维护了一个id->实际数据的hash_tale。对于一个resource，在zval中只记录了它的id。fetch的时候通过id在hash_table中找到具体的值返回。 
- 3 资源销毁：资源的数据类型是多种多样的。Zend本身没有办法销毁它。因此需要用户在注册资源的时候提供销毁函数。当unset资源时，zend调用相应的函数完成析构。同时从全局资源表中删除它。


#### php变量管理
引用计数在内存回收、字符串操作等地方使用非常广泛。Zval的引用计数通过成员变量is_ref和ref_count实现，
通过引用计数，多个变量可以共享同一份数据。避免频繁拷贝带来的大量消耗。
在进行赋值操作时，zend将变量指向相同的zval同时ref_count++，在unset操作时，对应的ref_count-1。
只有ref_count减为0时才会真正执行销毁操作。如果是引用赋值，则zend会修改is_ref为1。


PHP变量通过引用计数实现变量共享数据，那如果改变其中一个变量值呢？当试图写入一个变量时，Zend若发现该变量指向的zval被多个变量共享，则为其复制一份ref_count为1的zval，并递减原zval的refcount，这个过程称为“zval分离”。可见，只有在有写操作发生时 zend才进行拷贝操作，因此也叫copy-on-write(写时拷贝)






