---
title: "安装rabbitmq"
date: 2020-04-28T14:49:04+08:00
keywords: ["rabbitmq"]
categories: ["rabbitmq"]
tags: ["rabbitmq"]
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


- Erlang下载地址：[http://www.erlang.org/downloads](http://www.erlang.org/downloads)

- rabbitmq官网下载地址：[http://www.rabbitmq.com/download.html](http://www.rabbitmq.com/download.html)


#### CentOS7.x安装
1. 下载rabbitmq
```
wget https://dl.bintray.com/rabbitmq/all/rabbitmq-server/3.7.4/rabbitmq-server-3.7.4-1.el7.noarch.rpm
```
2. 安装erlang
```
yum install erlang
```
> 需要先安装yum EPEL源
```
yum install epel-release -y
# 或
rpm -vih http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-2.noarch.rpm
# 或
wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-2.noarch.rpm
rpm -vih epel-release-7-2.noarch.rpm
# 更新数据
yum clean all && yum makecache
```

> erlang下载地址[http://erlang.org/download/](http://erlang.org/download/)
源码安装：
```
wget http://erlang.org/download/otp_src_20.2.tar.gz

# 解压
tar -xzvf otp_src_20.2.tar.gz

# 安装依赖包
yum install -y gcc gcc-c++ unixODBC-devel openssl-devel ncurses-devel

# 设定安装位置
./configure --prefix=/usr/local/erlang --without-javac

# 安装
make && make install

# 添加环境变量
vi ~/.bash_profile

# 最后追加
PATH=$PATH:/usr/local/erlang
export PATH

# 保存退出
source ~/.bash_profile
```


3. 安装rabbitmq server
```
# 导入
rpm --import https://www.rabbitmq.com/rabbitmq-release-signing-key.asc

# 安装
yum install rabbitmq-server-3.7.4-1.el7.noarch.rpm

# 或者直接用yum源安装，但可能不是最新版本
yum -y install rabbitmq-server
```

4. 启动/停止rabbitmq服务器
```
service rabbitmq-server start/stop
```





