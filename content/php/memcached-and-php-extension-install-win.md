---
title: "windows环境下安装Memcached和php-memcached扩展以及安装php-memcache扩展"
date: 2020-09-15T14:12:53+08:00
keywords: ["php", "memcached"]
categories: ["php"]
tags: ["php", "memcached"]
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

## 准备
- xampp环境
- php-memcached扩展，地址[https://github.com/lifenglsf/php_memcached_dll](https://github.com/lifenglsf/php_memcached_dll)
- php-memcache扩展，地址[http://pecl.php.net/package/memcache/4.0.5.2/windows](http://pecl.php.net/package/memcache/4.0.5.2/windows)
- memcached下载地址[https://www.runoob.com/memcached/window-install-memcached.html](https://www.runoob.com/memcached/window-install-memcached.html)

### memcached安装
首先下载对应版本的memcached，我这里使用的是这个[http://static.runoob.com/download/memcached-1.4.5-amd64.zip](http://static.runoob.com/download/memcached-1.4.5-amd64.zip)

安装步骤详见：[https://www.runoob.com/memcached/window-install-memcached.html](https://www.runoob.com/memcached/window-install-memcached.html)

我这里只写1.4.5版本的安装

首先下载解压后，用管理员权限运行如下命令：
```shell script
schtasks /create /sc onstart /tn memcached /tr "'e:\memcached\memcached.exe' -m 512"

# /tn taskname 指定唯一识别这个计划任务的名称
# /sc schedule 指定计划频率
# /create 创建新计划任务
# /tr taskrun 指定在这个计划运行的程序的路径和文件名

# 如果需要删除，可以运行如下命令
schtasks /delete /tn memcached

# 设置开机启动后如何立马运行
schtasks /run /tn memcached

# 运行后如何终止正在运行的计划任务
schtasks /end /tn memcached

# 查看更多schtasks帮助
schtasks /?
```

### memcached的php扩展
首先phpinfo查看php版本，
http://localhost:8080/dashboard/phpinfo.php

然后根据Zend Extension Build和PHP Extension Build可以确定对应的memcached版本，
我这里的信息如下：
```shell script
Zend Extension Build	API320190902,TS,VC15
PHP Extension Build	API20190902,TS,VC15

# 注意后面的TS,VC15，找对应的memcached扩展也需要对应这个

```
根据上面给的github地址下载好对应版本的php_memcached.dll和libmemcached后，进行如下操作：

- 首先复制libmemcached.dll到windows/system32目录下
- 然后复制php_memcached.dll到xampp/php/ext目录下
- 最后再php.ini文件中添加一行extension=php_memcached.dll，保存重启apache即可

### memcache扩展安装
同样在phpinfo查看php版本，
http://localhost:8080/dashboard/phpinfo.php

然后根据Zend Extension Build和PHP Extension Build可以确定对应的memcache版本，
我这里的信息如下：
```shell script
Zend Extension Build	API320190902,TS,VC15
PHP Extension Build	API20190902,TS,VC15

# 注意后面的TS,VC15，找对应的memcache扩展也需要对应这个

```
根据上面给的下载地址，这里下载的是
[https://windows.php.net/downloads/pecl/releases/memcache/4.0.5.2/php_memcache-4.0.5.2-7.4-ts-vc15-x64.zip](https://windows.php.net/downloads/pecl/releases/memcache/4.0.5.2/php_memcache-4.0.5.2-7.4-ts-vc15-x64.zip)，

下载后解压进行如下操作：

- 复制php_memcache.dll到xampp/php/ext目录下
- 最后再php.ini文件中添加一行extension=php_memcache.dll，保存重启apache即可


### memcache可视化处理
最后，这里推荐一个memcache可视化工具，Memadmin，下载地址[ http://www.junopen.com/memadmin/]( http://www.junopen.com/memadmin/)

下载后解压到xampp/htdocs目录下，设置虚拟主机后即可访问


### Q&A
#### 在安装memcached的时候，遇到报错Failed to ignore SIGHUP: No error
原因：安装方式不正确，应该采用schtasks命令进行计划任务设置




