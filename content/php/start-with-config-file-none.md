---
title: "PHP启动时配置文件显示： Loaded Configuration File 为 none"
date: 2020-09-07T18:00:11+08:00
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

### PHP启动时配置文件显示： Loaded Configuration File 为 none

#### 首先查看php 的配置情况
```shell
php --ini
# 输出如下
Configuration File (php.ini) Path: /data/conf/etc/php.ini
Loaded Configuration File:         (none)
Scan for additional .ini files in: (none)
Additional .ini files parsed:      (none)

```

可以看到Loaded Configuration File的配置项为none，如果你直接在teminal中执行php运行代码，可能出现配置一些配置未加载的情况
，特别是一些扩展未加载情况导致的无法使用扩展

#### 解决方法
如果有strace，可以使用strace跟踪下php的执行情况
```shell
strace /usr/local/php/bin/php -i 2> /tmp/ll.log
# 然后使用grep查看跟踪中出现加载php.ini的路径
grep 'php.ini' /tmp/ll.log
# 结果如下：
open("/usr/local/php/bin/php.ini", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/usr/local/php/etc/php.ini", O_RDONLY) = -1 ENOENT (No such file or directory)
```
可以看到首先加载了/usr/local/php/bin/目录下的php.ini，发现没有该文件报错，然后又加载了
/usr/local/php/etc/php.ini，发现也不存在，需要解决的就是这个问题

我们可以直接复制你的php.ini文件到/usr/local/php/bin/目录下，让它自动加载即可
这时候重新执行php --ini可以看到结果如下

```shell
php --ini
Configuration File (php.ini) Path: /data/conf/etc/php-5.6.ini
Loaded Configuration File:         /usr/local/php-5.6.11/bin/php.ini
Scan for additional .ini files in: (none)
Additional .ini files parsed:      (none)
```
说明已经加载成功
