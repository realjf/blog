---
title: "unix网络编程 之 unp.h头文件安装配置"
date: 2019-11-23T08:17:24+08:00
keywords: ["unix", "unp", "network programming", "网络编程"]
categories: ["unix"]
tags: ["unix", "unp", "network programming", "网络编程"]
draft: false
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

unix网络编程环境之unp.h安装配置
====
官网[http://www.unpbook.com/src.html](http://www.unpbook.com/src.html)

### 1. 下载安装
```shell script
wget http://www.unpbook.com/unpv13e.tar.gz
tar zxvf unpv13e.tar.gz
cd unpv13e
./configure
cd lib
make
cd ../libfree
make
```
上面make遇到报错，如下
```shell script
gcc -I../lib -g -O2 -D_REENTRANT -Wall   -c -o in_cksum.o in_cksum.c
gcc -I../lib -g -O2 -D_REENTRANT -Wall   -c -o inet_ntop.o inet_ntop.c
inet_ntop.c: In function ‘inet_ntop’:
inet_ntop.c:60:9: error: argument ‘size’ doesn’t match prototype
  size_t size;
         ^~~~
In file included from inet_ntop.c:27:
/usr/include/arpa/inet.h:64:20: error: prototype declaration
 extern const char *inet_ntop (int __af, const void *__restrict __cp,
                    ^~~~~~~~~
make: *** [<builtin>: inet_ntop.o] Error 1
```
找到inet.h和inet_ntop.c对比发现，只要把size_t size改成socklen_t size即可，
这一步make会在上层目录生成libunp.a文件，如下为运行成功返回信息
```shell script
gcc -I../lib -g -O2 -D_REENTRANT -Wall   -c -o inet_ntop.o inet_ntop.c
/usr/include/arpa/inet.h: In function ‘inet_ntop’:
inet_ntop.c:152:23: warning: ‘best.len’ may be used uninitialized in this function [-Wmaybe-uninitialized]
   if (best.base == -1 || cur.len > best.len)
       ~~~~~~~~~~~~~~~~^~~~~~~~~~~~~~~~~~~~~
inet_ntop.c:123:28: note: ‘best.len’ was declared here
  struct { int base, len; } best, cur;
                            ^~~~
gcc -I../lib -g -O2 -D_REENTRANT -Wall   -c -o inet_pton.o inet_pton.c
ar rv ../libunp.a in_cksum.o inet_ntop.o inet_pton.o
a - in_cksum.o
a - inet_ntop.o
a - inet_pton.o
ranlib ../libunp.a
```
接下来继续编译
```shell script
cd ../libgai
make
```

> 注意，上面这两个make如果没有执行，在编译函数是小写时没出问题，但是程序含有大写函数时报错了，所以这两步要做

### 2. 复制
```shell script
cd ..
cp libunp.a /usr/lib
cp libunp.a /usr/lib64
```

### 3. 修改一些错误
1.在解压目录的lib目录下找到unp.h，在解压目录下有个文件config.h，
将unp.h中的#include "../config.h"修改为#include "config.h"

2.在unp.h中添加一行：#define MAX_LINE 2048

3. 将unp.h和config.h复制到以后我们存放源代码的同一目录下
```shell script
cp ./lib/unp.h /usr/include/
cp config.h /usr/include 
```

### 遇到的问题
#### 1. 在运行程序时，可能遇到undefined reference to 'err_quit'，undefined reference to 'err_sys' 情况
也是未定义的声明，也就是说这些函数没有实现，

**解决方法**

去官网把作者自己写的"apue.h"下载下来，把里面的相关错误输出取出来单独放入文件myerr.h中，
最后放入/usr/include/ 和自己存放源代码的目录下，就可以了

这里附上相关头文件

- [myerr.h](/files/myerr)
- [ourhdr.h](/files/ourhdr-h)

