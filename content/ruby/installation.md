---
title: "Ruby Installation"
date: 2019-08-30T12:42:08+08:00
draft: false
---

# centos7 下进行安装ruby

### 准备 下载ruby
ruby下载地址：[http://www.ruby-lang.org/en/downloads/](http://www.ruby-lang.org/en/downloads/)

这里以2.6.4版本为例
```shell
wget https://cache.ruby-lang.org/pub/ruby/2.6/ruby-2.6.4.tar.gz
```
### 解压配置安装
```shell
tar zxvf ruby-2.6.4.tar.gz -C /usr/local/
cd /usr/local/ruby-2.6.4/

./configure
make && make install

```
### 添加到环境变量中
```shell
ln -s /usr/local/ruby-2.6.4/ruby /usr/bin/ruby
```

### 验证
```shell
ruby -v
```
